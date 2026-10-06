import 'package:dio/dio.dart';

class MockResponse {
  const MockResponse(this.statusCode, [this.body]);
  final int statusCode;
  final Object? body;
}

typedef MockHandler = Future<MockResponse> Function(RequestOptions req);
