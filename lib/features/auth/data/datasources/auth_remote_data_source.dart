import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/features/auth/data/models/auth_response.dart';
import 'package:daybook/features/auth/data/models/user_model.dart';

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

  Future<UserModel> me() async {
    final data = await _api.get('/auth/me');
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => _api.post('/auth/logout');
}
