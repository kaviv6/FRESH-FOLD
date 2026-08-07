import '../../../core/network/api_client.dart';
import '../../../models/auth_result.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthResult> login({required String username, required String password}) async {
    final res = await _api.call('login', {
      'username': username,
      'password': password,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<AuthResult> signup({
    required String name,
    required String login,
    required String password,
    String? mobile,
    String? street,
    String? city,
  }) async {
    final res = await _api.call('signup', {
      'name': name,
      'login': login,
      'password': password,
      // Backend only reads 'phone' (see signup() in api_controller.py) —
      // it has no 'mobile' kwarg.
      if (mobile != null && mobile.isNotEmpty) 'phone': mobile,
      if (street != null && street.isNotEmpty) 'street': street,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<void> logout() => _api.call('logout');
}
