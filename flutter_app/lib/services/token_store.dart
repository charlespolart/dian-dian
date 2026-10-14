/// Persistent session identifiers (refresh token + user id).
///
/// Abstracted from the secure-storage plugin so [ApiService] can be unit
/// tested with an in-memory implementation.
abstract class TokenStore {
  Future<String?> getRefreshToken();
  Future<void> setRefreshToken(String token);
  Future<void> deleteRefreshToken();

  Future<String?> getUserId();
  Future<void> setUserId(String id);
  Future<void> deleteUserId();
}
