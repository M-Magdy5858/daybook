import 'dart:convert';
import 'dart:typed_data';

import 'package:daybook/core/network/auth_interceptor.dart';
import 'package:daybook/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage(this.access, this.refresh);
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> clear() async => access = refresh = null;
}

/// 401 unless the request carries `Bearer new`; refresh succeeds only when
/// [refreshWorks] is true.
class FakeServer implements HttpClientAdapter {
  FakeServer({this.refreshWorks = true});
  final bool refreshWorks;
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final (int status, Object body) = switch (options.path) {
      '/auth/refresh' when refreshWorks => (
        200,
        {'accessToken': 'new', 'refreshToken': 'r2'},
      ),
      '/auth/refresh' => (401, {'message': 'expired'}),
      _ when options.headers['Authorization'] == 'Bearer new' => (
        200,
        {'ok': true},
      ),
      _ => (401, {'message': 'expired'}),
    };
    if (options.path == '/auth/refresh') refreshCalls++;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  (Dio, AuthInterceptor) build(TokenStorage storage, FakeServer server) {
    Dio dio() =>
        Dio(BaseOptions(baseUrl: 'https://test'))..httpClientAdapter = server;
    final interceptor = AuthInterceptor(storage: storage, refreshDio: dio());
    return (dio()..interceptors.add(interceptor), interceptor);
  }

  test('3 parallel 401s -> exactly 1 refresh, all succeed', () async {
    final server = FakeServer();
    final (dio, _) = build(MemoryTokenStorage('old', 'r1'), server);

    final responses = await Future.wait([
      dio.get<Object?>('/a'),
      dio.get<Object?>('/b'),
      dio.get<Object?>('/c'),
    ]);

    expect(server.refreshCalls, 1);
    expect(responses.map((r) => r.statusCode), everyElement(200));
  });

  test('refresh fails -> storage cleared and session expired fires', () async {
    final storage = MemoryTokenStorage('old', 'r1');
    final (dio, interceptor) = build(storage, FakeServer(refreshWorks: false));
    final expired = expectLater(interceptor.onSessionExpired, emits(null));

    await expectLater(dio.get<Object?>('/a'), throwsA(isA<DioException>()));
    await expired;
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });
}
