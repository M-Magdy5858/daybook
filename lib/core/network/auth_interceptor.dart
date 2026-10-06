import 'dart:async';

import 'package:daybook/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Adds the access token to every request and, on a 401, refreshes it once
/// and retries the request.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.storage, required this.refreshDio});
  final TokenStorage storage;

  /// A separate Dio WITHOUT this interceptor, used for the refresh call and
  /// the retry. Retrying through the main Dio would queue the retry's own
  /// error behind the handler that's waiting for it, which never finishes.
  final Dio refreshDio;

  static const _noRefreshPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  };

  final _expired = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _expired.stream;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.readAccess();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _noRefreshPaths.contains(request.path)) {
      return handler.next(err);
    }

    // Another request may have refreshed while this one waited in the queue.
    // If so, just retry with the new token instead of refreshing again.
    final current = await storage.readAccess();
    final usedHeader = request.headers['Authorization'];
    if (current != null && usedHeader != 'Bearer $current') {
      return _retry(request, current, handler);
    }

    final refresh = await storage.readRefresh();
    if (refresh == null) return handler.next(err);

    final String access;
    try {
      final res = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      access = res.data!['accessToken'] as String;
      await storage.save(
        access: access,
        refresh: res.data!['refreshToken'] as String,
      );
    } catch (_) {
      await storage.clear();
      _expired.add(null); // tell the app the session is over
      return handler.next(err);
    }
    return _retry(request, access, handler);
  }

  Future<void> _retry(
    RequestOptions request,
    String access,
    ErrorInterceptorHandler handler,
  ) async {
    request.headers['Authorization'] = 'Bearer $access';
    try {
      handler.resolve(await refreshDio.fetch<Object?>(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
