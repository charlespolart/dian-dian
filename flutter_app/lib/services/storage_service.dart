import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_store.dart';
import 'token_store.dart';

class StorageService implements TokenStore, KeyStore {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _refreshTokenKey = 'refresh_token';
  static const _emailKey = 'user_email';
  static const _userIdKey = 'user_id';

  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  @override
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> getEmail() async {
    return _storage.read(key: _emailKey);
  }

  Future<void> setEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  Future<void> deleteEmail() async {
    await _storage.delete(key: _emailKey);
  }

  // The user id is kept next to the refresh token so an offline launch can
  // still identify whose cached data to show.
  @override
  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  @override
  Future<void> setUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  @override
  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  // The key of an invisible account, one entry per account id (chantier 9).
  // Default options on purpose: on iOS, an entry not synchronized through
  // iCloud, with the default accessibility — never a `*_this_device` one,
  // which an encrypted transfer to a new iPhone would leave behind.
  @override
  Future<String?> invisibleKey(String userId) => _storage.read(key: 'invisible_key_$userId');

  @override
  Future<void> setInvisibleKey(String userId, String key) => _storage.write(key: 'invisible_key_$userId', value: key);

  @override
  Future<void> deleteInvisibleKey(String userId) async {
    await _storage.delete(key: 'invisible_key_$userId');
    await _storage.delete(key: 'invisible_created_$userId');
  }

  @override
  Future<bool> invisibleCreated(String userId) async => await _storage.read(key: 'invisible_created_$userId') == 'yes';

  @override
  Future<void> markInvisibleCreated(String userId) => _storage.write(key: 'invisible_created_$userId', value: 'yes');
}
