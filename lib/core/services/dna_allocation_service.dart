import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:stork/core/native/dronecan/dynamic_node_id_allocation.dart';

class DnaAllocationHandler {
  final Uint8List uniqueId;
  final void Function(DynamicNodeIdAllocation message) onBroadcast;
  final void Function(int allocatedNodeId) onAllocated;

  Timer? _dnaTimer;
  int _dnaUniqueIdOffset = 0;
  bool _isAllocated = false;

  DnaAllocationHandler({
    required this.uniqueId,
    required this.onBroadcast,
    required this.onAllocated,
  });

  void start() {
    stop();
    _dnaUniqueIdOffset = 0;
    _isAllocated = false;
    _scheduleNextDnaRequest();
  }

  void stop() {
    _dnaTimer?.cancel();
    _dnaTimer = null;
    _dnaUniqueIdOffset = 0;
  }

  void _scheduleNextDnaRequest({bool isFollowup = false}) {
    _dnaTimer?.cancel();
    if (_isAllocated) {
      _dnaTimer?.cancel();
      return;
    }

    final random = math.Random();
    int delayMs;
    if (isFollowup) {
      // T_followup: between 0 and 400 ms
      delayMs = random.nextInt(401);
    } else {
      // T_request: between 600 and 1000 ms
      delayMs = 600 + random.nextInt(401);
    }

    _dnaTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_isAllocated) {
        _dnaTimer?.cancel();
        return;
      }
      _sendDnaRequest();
    });
  }

  void _sendDnaRequest() {
    final int remainingBytes = 16 - _dnaUniqueIdOffset;
    final int chunkSize = remainingBytes > 6 ? 6 : remainingBytes;
    if (chunkSize <= 0) {
      _dnaUniqueIdOffset = 0;
      _scheduleNextDnaRequest();
      return;
    }
    final chunk = uniqueId.sublist(
      _dnaUniqueIdOffset,
      _dnaUniqueIdOffset + chunkSize,
    );

    final dnaMsg = DynamicNodeIdAllocation(
      nodeId: 0,
      firstPartOfUniqueId: _dnaUniqueIdOffset == 0,
      uniqueId: chunk,
    );

    try {
      onBroadcast(dnaMsg);
      debugPrint(
        'DnaAllocationHandler: DNA request enqueued (offset: $_dnaUniqueIdOffset, chunk size: $chunkSize).',
      );
    } catch (e) {
      debugPrint('DnaAllocationHandler: Failed to broadcast DNA request: $e');
    } finally {
      _dnaUniqueIdOffset = 0;
      _scheduleNextDnaRequest();
    }
  }

  void handleAllocationMessage(DynamicNodeIdAllocation allocation) {
    if (_isAllocated) return;

    final receivedUid = allocation.uniqueId;
    if (receivedUid.isEmpty) return;

    bool matches = true;
    for (int i = 0; i < receivedUid.length; i++) {
      if (i >= uniqueId.length || receivedUid[i] != uniqueId[i]) {
        matches = false;
        break;
      }
    }

    if (matches) {
      if (allocation.nodeId > 0) {
        _isAllocated = true;
        debugPrint('DnaAllocationHandler: Dynamic Node ID Allocated: ${allocation.nodeId}');
        stop();
        onAllocated(allocation.nodeId);
      } else {
        debugPrint(
          'DnaAllocationHandler: Received DNA matching prefix of length ${receivedUid.length}, but nodeId is 0. Scheduling follow-up request...',
        );
        _dnaUniqueIdOffset = receivedUid.length;
        _scheduleNextDnaRequest(isFollowup: true);
      }
    } else {
      // Rule C: We received an allocation message for another node, or from another node.
      // Restart request timer with random T_request to avoid collisions.
      debugPrint(
        'DnaAllocationHandler: Rule C triggered (allocation activity from another node). Backing off DNA timer.',
      );
      _scheduleNextDnaRequest(isFollowup: false);
    }
  }
}
