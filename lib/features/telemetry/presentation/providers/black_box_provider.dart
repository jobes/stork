import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../map/presentation/providers/map_alert_history_provider.dart';
import 'black_box_repository_provider.dart';
import '../../domain/repositories/black_box_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/flight.dart';
import '../../domain/models/flight_alert_record.dart';
import '../../domain/models/telemetry_entry.dart';
import 'telemetry_provider.dart';
import 'flight_records_provider.dart';

part 'black_box_provider.g.dart';

@Riverpod(keepAlive: true)
class BlackBoxService extends _$BlackBoxService {
  static const _uuidGen = Uuid();

  String? _activeFlightUuid;
  DateTime? _flightStartedAt;
  Timer? _flushTimer;
  final List<TelemetryEntry> _buffer = [];
  final _alertBuffer = <(String, String), FlightAlertRecord>{};

  TelemetryState? _lastBufferedState;
  DateTime _lastKeyframeTime = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _activeFlushFuture;
  Future<void>? _flightCreationFuture;

  @override
  void build() {
    final repo = ref.read(blackBoxRepositoryProvider);
    // Keep the history's instrument listeners active with the dialog closed.
    ref.listen(mapAlertHistoryProvider, (_, _) {});
    final alertSubscription = ref
        .read(mapAlertHistoryProvider.notifier)
        .changes
        .listen(_bufferAlert);

    // Recover unfinished flights in the background
    unawaited(
      repo
          .recoverUnfinishedFlights()
          .then((_) {
            ref.read(flightRecordsProvider.notifier).refresh();
          })
          .catchError((e) {
            debugPrint('Error recovering unfinished flights: $e');
          }),
    );

    ref.onDispose(() {
      unawaited(alertSubscription.cancel());
      _flushTimer?.cancel();
      unawaited(
        _flush(forceRepo: repo).catchError((Object error) {
          debugPrint('Error flushing black box records on dispose: $error');
        }),
      );
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
      unawaited(_endFlight());
    } else if (isFlying) {
      _bufferTelemetry(next);
    }
  }

  void _startFlight(TelemetryState state) {
    if (_activeFlightUuid != null || _flightCreationFuture != null) return;

    final uuid = _uuidGen.v4();
    final now = DateTime.now().toUtc();
    final flightName =
        'Flight ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now.toLocal())}';
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
    _flightStartedAt = now;
    _lastKeyframeTime = now;
    _lastBufferedState = null;
    _buffer.clear();

    // Record the initial keyframe immediately in the memory buffer
    _bufferTelemetry(state);
    for (final entry in ref.read(mapAlertHistoryProvider)) {
      if (entry.endedAt == null) _bufferAlert(entry);
    }

    // Persist flight metadata asynchronously
    final repo = ref.read(blackBoxRepositoryProvider);
    _flightCreationFuture = repo
        .saveFlight(flight)
        .then((_) {
          // Reset the creation future now that the flight is persisted
          _flightCreationFuture = null;
          // Refresh flight records – handle errors separately so they don't clear flight state
          try {
            ref.read(flightRecordsProvider.notifier).refresh();
          } catch (e) {
            debugPrint('Error refreshing flight records after save: $e');
          }
          // Setup periodic database flusher (every 1 second) – isolated error handling
          try {
            if (_activeFlightUuid == uuid) {
              _flushTimer?.cancel();
              _flushTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
            }
          } catch (e) {
            debugPrint('Error initializing flush timer after save: $e');
          }
        })
        .catchError((e) {
          // Only handle errors from saveFlight itself
          _flightCreationFuture = null;
          _activeFlightUuid = null;
          _flightStartedAt = null;
          _alertBuffer.removeWhere((key, _) => key.$1 == uuid);
          _buffer
              .clear(); // Clear memory buffer on database initialization failure
          debugPrint('Error starting flight in database: $e');
          throw e;
        });
  }

  void _onTick(Timer timer) {
    if (_activeFlushFuture != null) return;
    if (_activeFlightUuid == null && _alertBuffer.isEmpty && _buffer.isEmpty) {
      timer.cancel();
      if (identical(timer, _flushTimer)) _flushTimer = null;
      return;
    }
    unawaited(
      _flush().catchError((e) {
        debugPrint('Error during periodic flush: $e');
      }),
    );
  }

  Future<void> _endFlight() async {
    final uuid = _activeFlightUuid;
    if (uuid == null) return;

    _activeFlightUuid = null; // Set null synchronously
    _flightStartedAt = null;
    final now = DateTime.now().toUtc();

    _flushTimer?.cancel();
    _flushTimer = null;

    // Flush any remaining entries in the buffer
    try {
      await _flush();
    } catch (e) {
      debugPrint('Error flushing telemetry at end of flight: $e');
      if (ref.mounted && _alertBuffer.isNotEmpty && _activeFlightUuid == null) {
        _flushTimer ??= Timer.periodic(const Duration(seconds: 1), _onTick);
      }
    }

    final repo = ref.read(blackBoxRepositoryProvider);
    try {
      await repo.updateFlightEndTime(uuid, now);
      await repo.calculateAndSaveFlightStatistics(uuid);
      ref.read(flightRecordsProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Error updating flight end time: $e');
    }

    if (_activeFlightUuid == null) _lastBufferedState = null;
  }

  void _bufferTelemetry(TelemetryState next) {
    final uuid = _activeFlightUuid;
    if (uuid == null) return;

    final now = DateTime.now().toUtc();

    // Determine if we need to record this state update
    if (_lastBufferedState != null &&
        !_hasStateChanged(_lastBufferedState!, next)) {
      return;
    }

    final isKeyframe = _shouldForceKeyframe(_lastBufferedState, next, now);
    final Map<String, dynamic> data = {};

    if (isKeyframe) {
      // Keyframe: save all non-null values
      for (final field in TelemetryField.blackBoxFields) {
        final val = next.getFieldValue(field);
        if (val != null) {
          data[field.dbColumnName] = val;
        }
      }
      _lastKeyframeTime = now;
      _lastBufferedState = next;
    } else {
      // Delta frame: compare with previously buffered state
      var updatedState = _lastBufferedState!;
      for (final field in TelemetryField.blackBoxFields) {
        if (!_areTelemetryFieldsEqual(_lastBufferedState!, next, field)) {
          final nextVal = next.getFieldValue(field);
          data[field.dbColumnName] = nextVal;
          updatedState = updatedState.copyWithField(field, nextVal);
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

  void _bufferAlert(MapAlertHistoryEntry entry) {
    final uuid = _activeFlightUuid;
    final flightStart = _flightStartedAt;
    if (uuid == null || flightStart == null) return;
    final alert = entry.alert;
    final startedAt = alert.since.isBefore(flightStart)
        ? flightStart
        : alert.since;
    final endedAt = entry.endedAt;
    _alertBuffer[(uuid, entry.id)] = FlightAlertRecord(
      flightUuid: uuid,
      episodeId: entry.id,
      kind: alert.kind.name,
      severity: alert.severity.name,
      startedAt: startedAt,
      endedAt: endedAt != null && endedAt.isBefore(startedAt)
          ? startedAt
          : endedAt,
      threshold: alert.instrumentIssue?.state.name,
      channel: alert.instrumentIssue?.channel,
      unavailable: alert.instrumentIssue?.unavailable ?? false,
    );
  }

  Future<void> _flush({BlackBoxRepository? forceRepo}) async {
    if (_buffer.isEmpty && _alertBuffer.isEmpty && _activeFlushFuture == null) {
      return;
    }

    final repo = forceRepo ?? ref.read(blackBoxRepositoryProvider);
    final creation = _flightCreationFuture;
    if (creation != null) await creation;
    while (_activeFlushFuture != null) {
      try {
        await _activeFlushFuture;
      } catch (_) {}
    }

    if (_buffer.isEmpty && _alertBuffer.isEmpty) return;

    final batch = List<TelemetryEntry>.from(_buffer);
    _buffer.clear();
    final alerts = Map.of(_alertBuffer);

    final flushCompleter = Completer<void>();
    _activeFlushFuture = flushCompleter.future;

    try {
      if (repo != null) {
        try {
          if (batch.isNotEmpty) await repo.insertTelemetryEntries(batch);
        } catch (e) {
          _buffer.insertAll(0, batch);
          rethrow;
        }
        if (alerts.isNotEmpty) {
          await repo.saveAlertRecords(alerts.values.toList());
          _alertBuffer.removeWhere(
            (key, value) => identical(value, alerts[key]),
          );
        }
      }
    } catch (e) {
      debugPrint('Error inserting black box records: $e');
      rethrow;
    } finally {
      flushCompleter.complete();
      _activeFlushFuture = null;
    }
  }

  bool _areListsEqual(List<double?> a, List<double?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _areTelemetryFieldsEqual(
    TelemetryState a,
    TelemetryState b,
    TelemetryField field,
  ) {
    if (field == TelemetryField.cylinderHeadTemperature) {
      return _areListsEqual(
        a.cylinderHeadTemperatures,
        b.cylinderHeadTemperatures,
      );
    }
    if (field == TelemetryField.exhaustGasTemperature) {
      return _areListsEqual(a.exhaustGasTemperatures, b.exhaustGasTemperatures);
    }
    return a.getFieldValue(field) == b.getFieldValue(field);
  }

  bool _isFieldNull(TelemetryState state, TelemetryField field) {
    if (field == TelemetryField.cylinderHeadTemperature) {
      return state.cylinderHeadTemperatures.isEmpty;
    }
    if (field == TelemetryField.exhaustGasTemperature) {
      return state.exhaustGasTemperatures.isEmpty;
    }
    return state.getFieldValue(field) == null;
  }

  bool _hasStateChanged(TelemetryState prev, TelemetryState next) {
    for (final field in TelemetryField.blackBoxFields) {
      if (!_areTelemetryFieldsEqual(prev, next, field)) {
        return true;
      }
    }
    return false;
  }

  bool _shouldForceKeyframe(
    TelemetryState? prev,
    TelemetryState next,
    DateTime now,
  ) {
    if (prev == null) return true;

    // Force keyframe if a sensor status changed (connected or disconnected / null transitions)
    for (final field in TelemetryField.blackBoxFields) {
      if (_isFieldNull(prev, field) != _isFieldNull(next, field)) {
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
