import 'package:daybook/core/network/mock/fake_jwt.dart';
import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:dio/dio.dart';

class AuthRoutes {
  AuthRoutes(this._state);
  final MockServerState _state;

  Map<String, MockHandler> get routes => {
    'POST /auth/login': _login,
    'POST /auth/register': _register,
    'GET /auth/me': _me,
    'POST /auth/refresh': _refresh,
    'POST /auth/logout': _logout,
  };

  Future<MockResponse> _login(RequestOptions req) async {
    final body = req.data as Map<String, dynamic>;
    final user = _state.users
        .where((u) => u.email == body['email'])
        .firstOrNull;
    if (user == null || user.password != body['password']) {
      return const MockResponse(401, {'message': 'Wrong email or password'});
    }
    return _session(200, user);
  }

  // _register: 422 with {'errors': {'email': 'Already used'}} for a duplicate, else 201 like login.
  Future<MockResponse> _register(RequestOptions req) async {
    final body = req.data as Map<String, dynamic>;
    final email = body['email'] as String;
    if (_state.users.any((u) => u.email == email)) {
      return const MockResponse(422, {
        'message': 'Validation failed',
        'errors': {'email': 'Already used'},
      });
    }
    final user = MockUser(
      '${_state.users.length + 1}',
      body['name'] as String,
      email,
      body['password'] as String,
    );
    _state.users.add(user);
    return _session(201, user);
  }

  // _me: read req.headers['Authorization'] ("Bearer <token>"); 401 if missing or expired, else 200 {'user': ...}.
  Future<MockResponse> _me(RequestOptions req) async {
    const unauthorized = MockResponse(401, {'message': 'Unauthorized'});
    final header = req.headers['Authorization'] as String?;
    if (header == null || !header.startsWith('Bearer ')) return unauthorized;

    final token = header.substring('Bearer '.length);
    if (FakeJwt.isExpired(token)) return unauthorized;

    final userId = FakeJwt.payload(token)['sub'];
    final user = _state.users.where((u) => u.id == userId).firstOrNull;
    if (user == null) return unauthorized;
    return MockResponse(200, {'user': user.toJson()});
  }

  // _refresh: a valid refresh token gets a new token pair; anything else is 401.
  Future<MockResponse> _refresh(RequestOptions req) async {
    const unauthorized = MockResponse(401, {'message': 'Session expired'});
    final body = req.data as Map<String, dynamic>?;
    final token = body?['refreshToken'] as String?;
    if (token == null || FakeJwt.isExpired(token)) return unauthorized;

    final userId = FakeJwt.payload(token)['sub'];
    final user = _state.users.where((u) => u.id == userId).firstOrNull;
    if (user == null) return unauthorized;
    return _session(200, user);
  }

  Future<MockResponse> _logout(RequestOptions req) async =>
      const MockResponse(200, {'message': 'Logged out'});

  MockResponse _session(int statusCode, MockUser user) =>
      MockResponse(statusCode, {
        'accessToken': FakeJwt.create(user.id, const Duration(minutes: 5)),
        'refreshToken': FakeJwt.create(user.id, const Duration(days: 30)),
        'user': user.toJson(),
      });
}
