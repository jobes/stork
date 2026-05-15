enum MapViewState {
  /// Initial map opening, suitable when we don't have an accurate GPS position yet.
  init,

  /// User requested GPS and we are waiting for a fix.
  waitingForGps,

  /// Navigation mode, follows the current position.
  follow,

  /// Overview mode, map is oriented to the North.
  overview,
}
