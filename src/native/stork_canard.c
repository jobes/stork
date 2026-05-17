#include "libcanard/canard.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#ifdef _WIN32
#define FFI_EXPORT __declspec(dllexport)
#else
#define FFI_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

#define ARENA_SIZE 8192

static CanardInstance g_canard;
static uint8_t g_arena[ARENA_SIZE];

static int16_t g_last_seq_no = -1;
static uint32_t g_seq_errors = 0;

typedef void (*StorkCanardLogCallback)(const char* message);
static StorkCanardLogCallback g_log_callback = NULL;

FFI_EXPORT void stork_canard_register_log_callback(StorkCanardLogCallback callback) {
    g_log_callback = callback;
    printf("stork_canard: Log callback registered\n");
    fflush(stdout);
}

static void stork_log(const char* format, ...) {
    char buffer[512];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);

    // Print to standard stdout
    printf("%s", buffer);
    fflush(stdout);

    // Call the Dart callback if registered
    if (g_log_callback != NULL) {
        g_log_callback(buffer);
    }
}

typedef void (*StorkCanardTransferCallback)(
    uint64_t timestamp_usec,
    uint16_t data_type_id,
    uint8_t transfer_type,
    uint8_t source_node_id,
    uint8_t transfer_id,
    const uint8_t* payload,
    uint16_t payload_len
);

static StorkCanardTransferCallback g_transfer_cb = NULL;

FFI_EXPORT void stork_canard_register_transfer_callback(StorkCanardTransferCallback cb) {
    g_transfer_cb = cb;
}

typedef uint8_t (*StorkCanardShouldAcceptCallback)(
    uint16_t data_type_id,
    uint8_t transfer_type,
    uint8_t source_node_id,
    uint64_t* out_data_type_signature
);

static StorkCanardShouldAcceptCallback g_accept_cb = NULL;

FFI_EXPORT void stork_canard_register_accept_callback(StorkCanardShouldAcceptCallback cb) {
    g_accept_cb = cb;
}

// Callback for transfer reception
void onTransferReception(CanardInstance* ins, CanardRxTransfer* transfer) {
    if (g_transfer_cb == NULL) return;

    // Create a flat buffer for the payload. DroneCAN messages are typically small, so a VLA on the stack is safe.
    uint8_t flat_payload[transfer->payload_len];
    
    // Optimization: Most messages (e.g. NodeStatus) are single-frame, where the buffer is already contiguous.
    if (transfer->payload_middle == NULL && transfer->payload_tail == NULL) {
        memcpy(flat_payload, transfer->payload_head, transfer->payload_len);
    } else {
        // For multi-frame messages (e.g. GetNodeInfo), extract byte by byte.
        for (uint16_t i = 0; i < transfer->payload_len; i++) {
            canardDecodeScalar(transfer, i * 8, 8, false, &flat_payload[i]);
        }
    }

    // Send the raw data to Dart
    g_transfer_cb(
        transfer->timestamp_usec,
        transfer->data_type_id,
        transfer->transfer_type,
        transfer->source_node_id,
        transfer->transfer_id,
        flat_payload,
        transfer->payload_len
    );
}

// Callback for transfer acceptance
bool shouldAcceptTransfer(const CanardInstance* ins, uint64_t* out_data_type_signature,
                          uint16_t data_type_id, CanardTransferType transfer_type, uint8_t source_node_id) {
    if (g_accept_cb != NULL) {
        return g_accept_cb(data_type_id, transfer_type, source_node_id, out_data_type_signature) != 0;
    }
    
    // Default signature if unknown
    *out_data_type_signature = 0; 
    return true;
}

// Initialize libcanard
FFI_EXPORT void stork_canard_init(uint8_t node_id) {
    canardInit(&g_canard, g_arena, sizeof(g_arena), onTransferReception, shouldAcceptTransfer, NULL);
    canardSetLocalNodeID(&g_canard, node_id);
    stork_log("stork_canard: Initialized with node_id=%d\n", node_id);
}

// Get pool statistics for debugging
FFI_EXPORT void stork_canard_get_stats(uint16_t* capacity, uint16_t* usage, uint16_t* peak, uint32_t* seq_errors) {
    CanardPoolAllocatorStatistics stats = canardGetPoolAllocatorStatistics(&g_canard);
    if (capacity) *capacity = stats.capacity_blocks;
    if (usage) *usage = stats.current_usage_blocks;
    if (peak) *peak = stats.peak_usage_blocks;
    if (seq_errors) *seq_errors = g_seq_errors;
}

// Process a Cannelloni packet containing multiple CAN/CAN-FD frames
FFI_EXPORT void stork_canard_process_packet(const uint8_t* data, uint32_t data_len, uint64_t timestamp_usec) {
    if (data_len < 5) {
        stork_log("stork_canard: Received too short packet (%d bytes)\n", data_len);
        return;
    }

    uint8_t version = data[0];
    uint8_t op_code = data[1];
    uint8_t seq_no = data[2];
    uint16_t count = ((uint16_t)data[3] << 8) | data[4];

    if (version != 2 || op_code != 0) {
        stork_log("stork_canard: Ignoring non-DATA packet (expected version=2, op_code=0)\n");
        return;
    }

    // Sequence tracking
    if (g_last_seq_no != -1) {
        uint8_t expected_seq = (uint8_t)((g_last_seq_no + 1) & 0xFF);
        if (seq_no != expected_seq) {
            uint8_t missed;
            if (seq_no > expected_seq) {
                missed = seq_no - expected_seq;
            } else {
                missed = (256 - expected_seq) + seq_no;
            }
            g_seq_errors += missed;
            stork_log("stork_canard: Sequence error detected! Expected %d, got %d. Missed packets: %d (Total errors: %u)\n", 
                      expected_seq, seq_no, missed, g_seq_errors);
        }
    }
    g_last_seq_no = seq_no;

    uint32_t offset = 5;
    for (uint16_t i = 0; i < count; i++) {
        if (offset + 5 > data_len) {
            stork_log("stork_canard: Breaking: frame %d header out of bounds (offset=%d, len=%d)\n", i, offset, data_len);
            break;
        }

        // CAN ID is uint32_t, big-endian (4 bytes)
        uint32_t can_id = ((uint32_t)data[offset] << 24) |
                          ((uint32_t)data[offset + 1] << 16) |
                          ((uint32_t)data[offset + 2] << 8) |
                          (uint32_t)data[offset + 3];

        uint8_t len_field = data[offset + 4];
        bool is_fd = (len_field & 0x80) != 0;
        uint8_t dlc = len_field & 0x7F;
        offset += 5;

        if (is_fd) {
            offset += 1; // Skip flags byte for CAN FD
        }

        if (offset + dlc > data_len) {
            stork_log("stork_canard: Breaking: frame %d data out of bounds (dlc=%d, offset=%d, len=%d)\n", i, dlc, offset, data_len);
            break;
        }

        // RTR frames (bit 30) have no data
        const uint32_t can_rtr_flag = 0x40000000;
        bool has_data = (can_id & can_rtr_flag) == 0;

        CanardCANFrame frame;
        frame.id = can_id;
        frame.data_len = dlc;

#if CANARD_ENABLE_CANFD
        frame.canfd = is_fd;
        uint8_t max_len = CANARD_CANFD_FRAME_MAX_DATA_LEN;
#else
        uint8_t max_len = CANARD_CAN_FRAME_MAX_DATA_LEN;
#endif

        if (has_data && dlc > 0) {
            if (frame.data_len > max_len) {
                frame.data_len = max_len;
            }
            memcpy(frame.data, &data[offset], frame.data_len);
            
            offset += dlc;
        } else {
            frame.data_len = 0;
        }

        int16_t res = canardHandleRxFrame(&g_canard, &frame, timestamp_usec);
    }
}

