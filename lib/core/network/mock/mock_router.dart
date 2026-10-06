import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:dio/dio.dart';

typedef MockParamHandler =
    Future<MockResponse> Function(
      RequestOptions req,
      Map<String, String> params,
    );

/// Matches `METHOD /path/:param` patterns to handlers.
class MockRouter {
  final _routes =
      <
        (
          String method,
          RegExp pattern,
          List<String> names,
          MockParamHandler handler,
        )
      >[];

  /// [path] like `/tasks/:id`.
  void on(String method, String path, MockParamHandler handler) {
    final names = <String>[];
    final regex = path.replaceAllMapped(RegExp(r':(\w+)'), (m) {
      names.add(m.group(1)!);
      return '([^/]+)';
    });
    _routes.add((method, RegExp('^$regex\$'), names, handler));
  }

  /// The matching handler's response, or `null` if no route matches.
  Future<MockResponse>? handle(RequestOptions req) {
    for (final (method, pattern, names, handler) in _routes) {
      final match = pattern.firstMatch(req.path);
      if (method == req.method && match != null) {
        return handler(req, {
          for (var i = 0; i < names.length; i++) names[i]: match.group(i + 1)!,
        });
      }
    }
    return null;
  }
}
