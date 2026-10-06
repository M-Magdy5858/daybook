/// The knobs the Developer tools page changes.
enum ForcedError {
  none,
  unauthorized,
  notFound,
  validation,
  server,
  timeout,
  offline,
}

class MockSettings {
  Duration latency = const Duration(milliseconds: 400);
  ForcedError forcedError = ForcedError.none;

  /// Every request fails with a connection error, like airplane mode.
  bool offline = false;
}
