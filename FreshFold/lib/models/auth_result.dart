/// Mirrors the `data` block returned by `POST /api/v1/login` and
/// `POST /api/v1/signup`.
class AuthResult {
  const AuthResult({
    required this.userId,
    required this.name,
    required this.token,
    required this.isRider,
    required this.isAdmin,
  });

  final int userId;
  final String name;
  final String token;
  final bool isRider;
  final bool isAdmin;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        userId: json['user_id'] as int,
        name: json['name'] as String? ?? '',
        token: json['token'] as String,
        // signup's response doesn't include role flags — a fresh signup is
        // always a plain customer (group_laundry_user), never rider/admin.
        isRider: json['is_rider'] as bool? ?? false,
        isAdmin: json['is_admin'] as bool? ?? false,
      );
}

enum AppRole { customer, rider, admin }
