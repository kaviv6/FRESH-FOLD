/// Mirrors the `data` block returned by `POST /api/v1/profile`.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.phone,
    required this.street,
    required this.street2,
    required this.city,
    required this.zip,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
  });

  final int userId;
  final String name;
  final String email;
  final String mobile;
  final String phone;
  final String street;
  final String street2;
  final String city;
  final String zip;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['user_id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        street: json['street'] as String? ?? '',
        street2: json['street2'] as String? ?? '',
        city: json['city'] as String? ?? '',
        zip: json['zip'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  /// Initials for the avatar bubble, e.g. "Anjali Mehta" -> "AM".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  String get addressSingleLine {
    final parts = [street, street2, city, zip]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
