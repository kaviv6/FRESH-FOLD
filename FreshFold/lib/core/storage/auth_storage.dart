import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the API bearer token and the small set of role flags the login
/// response returns, so the app can restore a session without another
/// network round trip on cold start.
class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'ff_api_token';
  static const _kUserId = 'ff_user_id';
  static const _kName = 'ff_name';
  static const _kIsRider = 'ff_is_rider';
  static const _kIsAdmin = 'ff_is_admin';

  Future<void> saveSession({
    required String token,
    required int userId,
    required String name,
    required bool isRider,
    required bool isAdmin,
  }) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kUserId, value: userId.toString()),
      _storage.write(key: _kName, value: name),
      _storage.write(key: _kIsRider, value: isRider.toString()),
      _storage.write(key: _kIsAdmin, value: isAdmin.toString()),
    ]);
  }

  Future<Map<String, String?>> readAll() async {
    return {
      'token': await _storage.read(key: _kToken),
      'userId': await _storage.read(key: _kUserId),
      'name': await _storage.read(key: _kName),
      'isRider': await _storage.read(key: _kIsRider),
      'isAdmin': await _storage.read(key: _kIsAdmin),
    };
  }

  Future<String?> readToken() => _storage.read(key: _kToken);

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
