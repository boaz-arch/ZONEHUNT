/// Reflects *why* the player's dot might not be trustworthy right now, so
/// the UI can show the right message instead of just silently freezing.
enum GpsStatus {
  /// Fresh, accurate fixes are coming in normally.
  ok,

  /// Location services are off at the OS level (Settings > Location).
  disabled,

  /// The app asked for location permission and the user said no.
  permissionDenied,

  /// The user said no and checked "don't ask again" (Android) / selected
  /// "Never" (iOS). Requesting again silently does nothing; the user has
  /// to go into system settings.
  permissionDeniedForever,

  /// We haven't received *any* fix (good or bad) for longer than
  /// [signalLostTimeout]. Usually indoors, a tunnel, or airplane mode.
  signalLost,

  /// Fixes are arriving, but their accuracy radius is too wide to trust
  /// for an outside-zone/elimination decision.
  poorAccuracy,
}
