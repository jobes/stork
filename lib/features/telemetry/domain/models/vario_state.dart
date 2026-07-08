enum VarioSource { baro, gps, none }

class VarioState {
  final double? verticalSpeed;
  final VarioSource source;
  final DateTime? lastUpdate;

  const VarioState({
    this.verticalSpeed,
    this.source = VarioSource.none,
    this.lastUpdate,
  });

  VarioState copyWith({
    double? verticalSpeed,
    VarioSource? source,
    DateTime? lastUpdate,
  }) {
    return VarioState(
      verticalSpeed: verticalSpeed ?? this.verticalSpeed,
      source: source ?? this.source,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  String toString() =>
      'VarioState(verticalSpeed: $verticalSpeed, source: $source, lastUpdate: $lastUpdate)';
}
