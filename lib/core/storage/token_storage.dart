import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<void> save({required String access, required String refresh});
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  // Cached in memory so each request doesn't hit the Keychain.
  String? _access;

  @override
  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  @override
  Future<String?> readAccess() async =>
      _access ??= await _storage.read(key: 'access');

  @override
  Future<String?> readRefresh() => _storage.read(key: 'refresh');

  @override
  Future<void> clear() async {
    _access = null;
    await _storage.deleteAll();
  }
}
