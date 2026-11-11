/// A single alert episode observed during a black box flight recording.
class FlightAlertRecord {
  const FlightAlertRecord({
    required this.flightUuid,
    required this.episodeId,
    required this.kind,
    required this.severity,
    required this.startedAt,
    this.endedAt,
    this.threshold,
    this.channel,
    this.unavailable = false,
  });

  final String flightUuid;
  final String episodeId;
  final String kind;
  final String severity;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? threshold;
  final int? channel;
  final bool unavailable;
}
