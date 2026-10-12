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

  /// Only requests to this path (e.g. `/tasks`) get [forcedError]; null
  /// means every request.
  String? forcedErrorPath;

  /// The [forcedError] for a request to [path].
  ForcedError forcedErrorFor(String path) {
    final only = forcedErrorPath;
    return only == null || path == only || path.startsWith('$only/')
        ? forcedError
        : ForcedError.none;
  }

  /// Every request fails with a connection error, like airplane mode.
  bool offline = false;
}
