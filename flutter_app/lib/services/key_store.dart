/// The key of an invisible account (chantier 9): 32 random bytes made by the
/// phone, kept in its secure storage — on iOS a keychain entry that is not
/// synchronized, never a `*_this_device` one — and sent only to
/// `/api/auth/invisible` and `/api/auth/key`. Abstracted from the plugin so
/// [ApiService] can be unit tested in memory.
abstract class KeyStore {
  Future<String?> invisibleKey(String userId);
  Future<void> setInvisibleKey(String userId, String key);

  /// Forgets the key and the mark below (the account was deleted).
  Future<void> deleteInvisibleKey(String userId);

  /// Whether the server already has the account: `/api/auth/key` reopens
  /// it; until then, `/api/auth/invisible` creates it (case 5).
  Future<bool> invisibleCreated(String userId);
  Future<void> markInvisibleCreated(String userId);
}

/// A phone with no key at all: the token store of a test or of the
/// end-to-end harness, which only sign in by address.
class NoKeys implements KeyStore {
  const NoKeys();
  @override
  Future<String?> invisibleKey(String userId) async => null;
  @override
  Future<void> setInvisibleKey(String userId, String key) async => throw UnsupportedError('No key store');
  @override
  Future<void> deleteInvisibleKey(String userId) async {}
  @override
  Future<bool> invisibleCreated(String userId) async => false;
  @override
  Future<void> markInvisibleCreated(String userId) async {}
}
