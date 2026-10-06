import 'dart:convert';
import 'dart:typed_data';

import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:dio/dio.dart';

class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter(this._settings, this._routes);
  final MockSettings _settings;
  final Map<String, MockHandler> _routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    await Future<void>.delayed(_settings.latency);

    final response = switch (_settings.forcedError) {
      ForcedError.offline => throw DioException.connectionError(
        requestOptions: options,
        reason: 'Simulated offline',
      ),
      ForcedError.timeout => throw DioException.receiveTimeout(
        timeout: options.receiveTimeout ?? Duration.zero,
        requestOptions: options,
      ),
      ForcedError.unauthorized => const MockResponse(401, {
        'message': 'Simulated 401',
      }),
      ForcedError.notFound => const MockResponse(404, {
        'message': 'Simulated 404',
      }),
      ForcedError.validation => const MockResponse(422, {
        'message': 'Simulated 422',
        'errors': {},
      }),
      ForcedError.server => const MockResponse(500, {
        'message': 'Simulated 500',
      }),
      ForcedError.none => await _handle(options),
    };

    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Future<MockResponse> _handle(RequestOptions options) async {
    final handler = _routes['${options.method} ${options.path}'];
    if (handler == null) {
      return const MockResponse(404, {'message': 'No such route'});
    }
    try {
      return await handler(options);
    } catch (e) {
      // A bug in a mock handler should read as a server error, not a
      // network failure.
      return MockResponse(500, {'message': 'Mock handler failed: $e'});
    }
  }

  @override
  void close({bool force = false}) {}
}
