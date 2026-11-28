/// What the phone keeps per account in its secure storage (chantier 9). The
/// key of an invisible account: 32 random bytes made by the phone — on iOS a
/// keychain entry that is not synchronized, never a `*_this_device` one —
/// sent only to `/api/auth/invisible` and `/api/auth/key`. Abstracted from
/// the plugin so [ApiService] can be unit tested in memory.
abstract class KeyStore {
  Future<String?> invisibleKey(String userId);
  Future<void> setInvisibleKey(String userId, String key);

  /// Forgets everything kept for the account: its key and both marks below
  /// (the account was deleted, or left on this phone).
  Future<void> forgetAccount(String userId);

  /// Whether the server already has the account: `/api/auth/key` reopens
  /// it; until then, `/api/auth/invisible` creates it (case 5).
  Future<bool> invisibleCreated(String userId);
  Future<void> markInvisibleCreated(String userId);

  /// A deletion of the account was asked here and its answer never came:
  /// the server may have done it. A later « account deleted » is then that
  /// deletion, not one made on another device (case 66).
  Future<bool> deletionAsked(String userId);
  Future<void> markDeletionAsked(String userId);
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
  Future<void> forgetAccount(String userId) async {}
  @override
  Future<bool> invisibleCreated(String userId) async => false;
  @override
  Future<void> markInvisibleCreated(String userId) async {}
  @override
  Future<bool> deletionAsked(String userId) async => false;
  @override
  Future<void> markDeletionAsked(String userId) async {}
}
