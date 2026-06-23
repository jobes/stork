import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/database/black_box_database.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/flight.dart';
import '../../domain/models/telemetry_entry.dart';
import '../../domain/models/telemetry_state.dart';
import 'telemetry_provider.dart';

part 'black_box_provider.g.dart';

@Riverpod(keepAlive: true)
class BlackBoxService extends _$BlackBoxService {
  static const _uuidGen = Uuid();

  String? _activeFlightUuid;
  Timer? _flushTimer;
  final List<TelemetryEntry> _buffer = [];

  TelemetryState? _lastBufferedState;
  DateTime _lastKeyframeTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void build() {
    ref.onDispose(() {
      _flushTimer?.cancel();
      _flush();
    });

    ref.listen<TelemetryState>(telemetryProvider, (previous, next) {
      _handleTelemetryChange(previous, next);
    });

    // Check initial state in case the app was started while flying
    final initialTelemetry = ref.read(telemetryProvider);
    if (initialTelemetry.isFlying) {
      _startFlight(initialTelemetry);
    }
  }

  String? get activeFlightUuid => _activeFlightUuid;

  void _handleTelemetryChange(TelemetryState? previous, TelemetryState next) {
    final wasFlying = previous?.isFlying ?? false;
    final isFlying = next.isFlying;

    if (isFlying && !wasFlying) {
      _startFlight(next);
    } else if (!isFlying && wasFlying) {
      _endFlight();
    } else if (isFlying) {
      _bufferTelemetry(next);
    }
  }

  void _startFlight(TelemetryState state) {
    if (_activeFlightUuid != null) return;

    final uuid = _uuidGen.v4();
    final now = DateTime.now().toUtc();
    final flightName = 'Flight ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now.toLocal())}';

    // Retrieve active pilot and airplane from AppSettings
    final settings = ref.read(appSettingsProvider).value;
    final pilotId = settings?.pilotId;
    final airplaneId = settings?.airplaneId;

    final flight = Flight(
      uuid: uuid,
      name: flightName,
      startTime: now,
      pilotId: pilotId,
      airplaneId: airplaneId,
    );

    _activeFlightUuid = uuid;
    _lastKeyframeTime = now;
    _lastBufferedState = null;
    _buffer.clear();

    // Persist flight metadata asynchronously
    unawaited(BlackBoxDatabase.saveFlight(flight).catchError((e) {
      debugPrint('Error starting flight in database: $e');
    }));

    // Record the initial keyframe
    _bufferTelemetry(state);

    // Setup periodic database flusher (every 1 second)
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 1), (_) => _flush());
  }

  void _endFlight() {
    final uuid = _activeFlightUuid;
    if (uuid == null) return;

    _flushTimer?.cancel();
    _flushTimer = null;

    // Flush any remaining entries in the buffer
    _flush();

    final now = DateTime.now().toUtc();
    unawaited(BlackBoxDatabase.updateFlightEndTime(uuid, now).catchError((e) {
      debugPrint('Error updating flight end time: $e');
    }));

    _activeFlightUuid = null;
    _lastBufferedState = null;
  }

  Map<String, dynamic> _stateToMap(TelemetryState state) {
    final map = <String, dynamic>{};
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      map[field.dbColumnName] = state.getFieldValue(field);
    }
    return map;
  }

  void _bufferTelemetry(TelemetryState next) {
    final uuid = _activeFlightUuid;
    if (uuid == null) return;

    final now = DateTime.now().toUtc();

    // Determine if we need to record this state update
    if (_lastBufferedState != null && !_hasStateChanged(_lastBufferedState!, next)) {
      return;
    }

    final isKeyframe = _shouldForceKeyframe(_lastBufferedState, next, now);
    final currentMap = _stateToMap(next);
    final Map<String, dynamic> data = {};

    if (isKeyframe) {
      // Keyframe: save all non-null values
      currentMap.forEach((key, value) {
        if (value != null) {
          data[key] = value;
        }
      });
      _lastKeyframeTime = now;
      _lastBufferedState = next;
    } else {
      // Delta frame: compare with previously buffered state
      final prevMap = _stateToMap(_lastBufferedState!);
      currentMap.forEach((key, value) {
        if (value != prevMap[key]) {
          data[key] = value; // stores new value (even null, meaning offline!)
        }
      });

      // Keep our buffered state tracker in sync with the database values
      var updatedState = _lastBufferedState!;
      for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
        final key = field.dbColumnName;
        if (data.containsKey(key)) {
          updatedState = updatedState.copyWithField(field, data[key]);
        }
      }
      _lastBufferedState = updatedState.copyWith(
        isFlying: next.isFlying,
        isGpsDroneCan: next.isGpsDroneCan,
        mapViewState: next.mapViewState,
      );
    }

    final entry = TelemetryEntry(
      flightUuid: uuid,
      timestamp: now,
      isSnapshot: isKeyframe,
      data: data,
    );

    _buffer.add(entry);
  }

  void _flush() {
    if (_buffer.isEmpty) return;

    final batch = List<TelemetryEntry>.from(_buffer);
    _buffer.clear();

    unawaited(BlackBoxDatabase.insertTelemetryEntries(batch).catchError((e) {
      debugPrint('Error inserting black box telemetry: $e');
    }));
  }

  bool _hasStateChanged(TelemetryState prev, TelemetryState next) {
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      if (prev.getFieldValue(field) != next.getFieldValue(field)) {
        return true;
      }
    }
    return false;
  }

  bool _shouldForceKeyframe(TelemetryState? prev, TelemetryState next, DateTime now) {
    if (prev == null) return true;

    // Force keyframe if a sensor status changed (connected or disconnected / null transitions)
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      final prevVal = prev.getFieldValue(field);
      final nextVal = next.getFieldValue(field);
      if ((prevVal == null) != (nextVal == null)) {
        return true;
      }
    }

    // Force keyframe every 10 seconds to make seeking/decoding simple
    if (now.difference(_lastKeyframeTime) >= const Duration(seconds: 10)) {
      return true;
    }

    return false;
  }
}
