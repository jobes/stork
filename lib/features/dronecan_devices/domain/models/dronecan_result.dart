/// Result of an operation on a DroneCAN node.
///
/// Repositories throw, notifiers catch and expose either [DroneCanSuccess] or
/// [DroneCanFailure] so the UI never has to handle exceptions itself.
sealed class DroneCanResult<T> {
  const DroneCanResult();

  bool get isSuccess => this is DroneCanSuccess<T>;

  /// Value of a successful result, or `null` when the operation failed.
  T? get valueOrNull => switch (this) {
    DroneCanSuccess<T>(:final value) => value,
    DroneCanFailure<T>() => null,
  };
}

final class DroneCanSuccess<T> extends DroneCanResult<T> {
  const DroneCanSuccess(this.value);

  final T value;
}

final class DroneCanFailure<T> extends DroneCanResult<T> {
  const DroneCanFailure(this.error);

  /// Exception thrown by the repository.
  final Object error;
}

/// Failures that the notifiers detect themselves, before calling a repository.
///
/// They are returned as [DroneCanFailure.error] so the presentation layer can
/// keep using a localized message instead of displaying English text.
enum DroneCanOperationFailure { busy, parametersNotStored, parametersNotErased }
