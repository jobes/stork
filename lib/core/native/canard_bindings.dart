import 'dart:ffi';
import 'dart:io';

enum CanardTransferType {
  response(0),
  request(1),
  broadcast(2);

  final int value;
  const CanardTransferType(this.value);

  static CanardTransferType fromInt(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () =>
          throw ArgumentError('Invalid CanardTransferType value: $value'),
    );
  }
}

typedef StorkCanardInitNative = Void Function(Uint8 nodeId);
typedef StorkCanardInit = void Function(int nodeId);

typedef StorkCanardGetStatsNative =
    Void Function(
      Pointer<Uint16> capacity,
      Pointer<Uint16> usage,
      Pointer<Uint16> peak,
      Pointer<Uint32> seqErrors,
    );
typedef StorkCanardGetStats =
    void Function(
      Pointer<Uint16> capacity,
      Pointer<Uint16> usage,
      Pointer<Uint16> peak,
      Pointer<Uint32> seqErrors,
    );

typedef StorkCanardProcessPacketNative =
    Void Function(Pointer<Uint8> data, Uint32 dataLen, Uint64 timestampUsec);
typedef StorkCanardProcessPacket =
    void Function(Pointer<Uint8> data, int dataLen, int timestampUsec);

typedef StorkCanardLogCallbackNative = Void Function(Pointer<Char> message);
typedef StorkCanardRegisterLogCallbackNative =
    Void Function(
      Pointer<NativeFunction<StorkCanardLogCallbackNative>> callback,
    );
typedef StorkCanardRegisterLogCallback =
    void Function(
      Pointer<NativeFunction<StorkCanardLogCallbackNative>> callback,
    );

typedef StorkCanardTransferCallbackNative =
    Void Function(
      Uint64 timestampUsec,
      Uint16 dataTypeId,
      Uint8 transferType,
      Uint8 sourceNodeId,
      Uint8 transferId,
      Uint8 priority,
      Pointer<Uint8> payload,
      Uint16 payloadLen,
    );

typedef StorkCanardRegisterTransferCallbackNative =
    Void Function(
      Pointer<NativeFunction<StorkCanardTransferCallbackNative>> callback,
    );

typedef StorkCanardRegisterTransferCallback =
    void Function(
      Pointer<NativeFunction<StorkCanardTransferCallbackNative>> callback,
    );

typedef StorkCanardShouldAcceptCallbackNative =
    Uint8 Function(
      Uint16 dataTypeId,
      Uint8 transferType,
      Uint8 sourceNodeId,
      Pointer<Uint64> outDataTypeSignature,
    );

typedef StorkCanardRegisterAcceptCallbackNative =
    Void Function(
      Pointer<NativeFunction<StorkCanardShouldAcceptCallbackNative>> callback,
    );

typedef StorkCanardRegisterAcceptCallback =
    void Function(
      Pointer<NativeFunction<StorkCanardShouldAcceptCallbackNative>> callback,
    );

typedef StorkCanardBroadcastNative =
    Int16 Function(
      Uint64 dataTypeSignature,
      Uint16 dataTypeId,
      Pointer<Uint8> inoutTransferId,
      Uint8 priority,
      Pointer<Uint8> payload,
      Uint16 payloadLen,
    );
typedef StorkCanardBroadcast =
    int Function(
      int dataTypeSignature,
      int dataTypeId,
      Pointer<Uint8> inoutTransferId,
      int priority,
      Pointer<Uint8> payload,
      int payloadLen,
    );

typedef StorkCanardGenerateTxPacketNative =
    Int32 Function(Pointer<Uint8> outBuffer, Uint32 maxLen);
typedef StorkCanardGenerateTxPacket =
    int Function(Pointer<Uint8> outBuffer, int maxLen);

typedef StorkCanardRespondNative =
    Int16 Function(
      Uint64 dataTypeSignature,
      Uint16 dataTypeId,
      Uint8 transferId,
      Uint8 destinationNodeId,
      Uint8 priority,
      Pointer<Uint8> payload,
      Uint16 payloadLen,
    );
typedef StorkCanardRespond =
    int Function(
      int dataTypeSignature,
      int dataTypeId,
      int transferId,
      int destinationNodeId,
      int priority,
      Pointer<Uint8> payload,
      int payloadLen,
    );

class CanardBindings {
  late DynamicLibrary _lib;
  late StorkCanardInit storkCanardInit;

  late StorkCanardGetStats storkCanardGetStats;
  late StorkCanardProcessPacket storkCanardProcessPacket;
  late StorkCanardRegisterLogCallback storkCanardRegisterLogCallback;
  late StorkCanardRegisterTransferCallback storkCanardRegisterTransferCallback;
  late StorkCanardRegisterAcceptCallback storkCanardRegisterAcceptCallback;
  late StorkCanardBroadcast storkCanardBroadcast;
  late StorkCanardGenerateTxPacket storkCanardGenerateTxPacket;
  late StorkCanardRespond storkCanardRespond;

  CanardBindings() {
    if (Platform.isLinux) {
      _lib = DynamicLibrary.executable();
    } else if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libstork_canard.so');
    } else {
      // Fallback or other platforms
      throw UnsupportedError('Platform not supported for libcanard');
    }

    storkCanardInit = _lib
        .lookup<NativeFunction<StorkCanardInitNative>>('stork_canard_init')
        .asFunction();

    storkCanardGetStats = _lib
        .lookup<NativeFunction<StorkCanardGetStatsNative>>(
          'stork_canard_get_stats',
        )
        .asFunction();

    storkCanardProcessPacket = _lib
        .lookup<NativeFunction<StorkCanardProcessPacketNative>>(
          'stork_canard_process_packet',
        )
        .asFunction();

    storkCanardRegisterLogCallback = _lib
        .lookup<NativeFunction<StorkCanardRegisterLogCallbackNative>>(
          'stork_canard_register_log_callback',
        )
        .asFunction();

    storkCanardRegisterTransferCallback = _lib
        .lookup<NativeFunction<StorkCanardRegisterTransferCallbackNative>>(
          'stork_canard_register_transfer_callback',
        )
        .asFunction();

    storkCanardRegisterAcceptCallback = _lib
        .lookup<NativeFunction<StorkCanardRegisterAcceptCallbackNative>>(
          'stork_canard_register_accept_callback',
        )
        .asFunction();

    storkCanardBroadcast = _lib
        .lookup<NativeFunction<StorkCanardBroadcastNative>>(
          'stork_canard_broadcast',
        )
        .asFunction();

    storkCanardGenerateTxPacket = _lib
        .lookup<NativeFunction<StorkCanardGenerateTxPacketNative>>(
          'stork_canard_generate_tx_packet',
        )
        .asFunction();

    storkCanardRespond = _lib
        .lookup<NativeFunction<StorkCanardRespondNative>>(
          'stork_canard_respond',
        )
        .asFunction();
  }
}
