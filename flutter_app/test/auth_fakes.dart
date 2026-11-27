import 'package:dian_dian/services/storage_service.dart';

/// The phone's secure storage, in memory.
class FakeStorage implements StorageService {
  final values = <String, String>{};
  @override
  Future<String?> getRefreshToken() async => values['refresh'];
  @override
  Future<void> setRefreshToken(String token) async => values['refresh'] = token;
  @override
  Future<void> deleteRefreshToken() async => values.remove('refresh');
  @override
  Future<String?> getUserId() async => values['user'];
  @override
  Future<void> setUserId(String id) async => values['user'] = id;
  @override
  Future<void> deleteUserId() async => values.remove('user');
  @override
  Future<String?> getEmail() async => values['email'];
  @override
  Future<void> setEmail(String email) async => values['email'] = email;
  @override
  Future<void> deleteEmail() async => values.remove('email');
  @override
  Future<String?> invisibleKey(String userId) async => values['key:$userId'];
  @override
  Future<void> setInvisibleKey(String userId, String key) async => values['key:$userId'] = key;
  @override
  Future<void> deleteInvisibleKey(String userId) async {
    values.remove('key:$userId');
    values.remove('created:$userId');
  }

  @override
  Future<bool> invisibleCreated(String userId) async => values['created:$userId'] == 'yes';
  @override
  Future<void> markInvisibleCreated(String userId) async => values['created:$userId'] = 'yes';
}
