/// Outcome of a manual `GetNodeInfo` refresh of all known DroneCAN nodes.
///
/// A node that does not implement `GetNodeInfo` never answers, so the refresh
/// reports how many nodes responded instead of failing as a whole.
class DroneCanNodeInfoRefresh {
  const DroneCanNodeInfoRefresh({
    required this.requested,
    required this.answered,
  });

  /// Number of nodes the request was sent to.
  final int requested;

  /// Number of nodes that answered within this refresh.
  final int answered;

  /// Whether there was no node to ask.
  bool get isEmpty => requested == 0;

  /// Whether every known node answered.
  bool get isComplete => requested > 0 && answered == requested;
}
