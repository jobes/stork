import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'airspace_data_status_provider.g.dart';

/// Availability of the real-time airspace activity (AUP/UUP) data.
@immutable
class AirspaceDataStatusState {
  const AirspaceDataStatusState({this.failedFirs = const {}});

  /// FIRs for which the latest AUP/UUP fetch failed.
  final Set<String> failedFirs;

  bool get hasError => failedFirs.isNotEmpty;

  AirspaceDataStatusState copyWith({Set<String>? failedFirs}) {
    return AirspaceDataStatusState(failedFirs: failedFirs ?? this.failedFirs);
  }

  @override
  bool operator ==(Object other) =>
      other is AirspaceDataStatusState &&
      setEquals(other.failedFirs, failedFirs);

  @override
  int get hashCode => Object.hashAllUnordered(failedFirs);

  @override
  String toString() => 'AirspaceDataStatusState(failedFirs: $failedFirs)';
}

/// Tracks which FIRs currently have no fresh AUP/UUP data.
///
/// The real-time airspace controller reports every fetch result here. Keeping
/// this in a separate provider lets the map status indicator react to a failed
/// download without changing the activity state consumed by the map layers.
@Riverpod(keepAlive: true)
class AirspaceDataStatus extends _$AirspaceDataStatus {
  @override
  AirspaceDataStatusState build() => const AirspaceDataStatusState();

  void markSuccess(String firIcao) {
    if (!state.failedFirs.contains(firIcao)) return;
    state = state.copyWith(
      failedFirs: Set.unmodifiable(
        Set<String>.of(state.failedFirs)..remove(firIcao),
      ),
    );
  }

  void markFailure(String firIcao) {
    if (state.failedFirs.contains(firIcao)) return;
    state = state.copyWith(
      failedFirs: Set.unmodifiable({...state.failedFirs, firIcao}),
    );
  }

  /// Drops failures for FIRs the aircraft has left.
  void prune(Set<String> nearbyFirs) {
    final remaining = state.failedFirs.where(nearbyFirs.contains).toSet();
    if (remaining.length == state.failedFirs.length) return;
    state = state.copyWith(failedFirs: Set.unmodifiable(remaining));
  }
}
