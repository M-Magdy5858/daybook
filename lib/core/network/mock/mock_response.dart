class MockResponse {
  const MockResponse(this.statusCode, [this.body]);
  final int statusCode;
  final Object? body;
}
