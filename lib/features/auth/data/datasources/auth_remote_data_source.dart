import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/features/auth/data/models/auth_response.dart';

/// The only class that knows the auth URLs.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AuthResponse> login(String email, String password) async =>
      AuthResponse.fromJson(
        await _api.post(
          '/auth/login',
          body: {'email': email, 'password': password},
        ),
      );

  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async => AuthResponse.fromJson(
    await _api.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    ),
  );
}
