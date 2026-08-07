/// Mirrors one entry of the `POST /api/v1/address/list` response — either
/// the customer's own partner record (`is_primary: true`, can't be deleted)
/// or one of its `type='delivery'` child contacts.
class Address {
  const Address({
    required this.id,
    required this.isPrimary,
    required this.isDefault,
    required this.label,
    required this.street,
    required this.street2,
    required this.city,
    required this.zip,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
  });

  final int id;
  final bool isPrimary;
  final bool isDefault;
  final String label;
  final String street;
  final String street2;
  final String city;
  final String zip;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;

  String get singleLine {
    final parts = [street, street2, city, zip]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as int,
        isPrimary: json['is_primary'] as bool? ?? false,
        isDefault: json['is_default'] as bool? ?? false,
        label: json['label'] as String? ?? 'Address',
        street: json['street'] as String? ?? '',
        street2: json['street2'] as String? ?? '',
        city: json['city'] as String? ?? '',
        zip: json['zip'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

/// Mirrors the `data` block returned by `POST /api/v1/geocode/reverse`.
/// Fields are best-effort (from OpenStreetMap Nominatim) — meant to
/// pre-fill the address form, not as a validated final answer.
class ReverseGeocodeResult {
  const ReverseGeocodeResult({
    required this.street,
    required this.street2,
    required this.city,
    required this.zip,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String street;
  final String street2;
  final String city;
  final String zip;
  final String state;
  final String country;
  final double latitude;
  final double longitude;

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) => ReverseGeocodeResult(
        street: json['street'] as String? ?? '',
        street2: json['street2'] as String? ?? '',
        city: json['city'] as String? ?? '',
        zip: json['zip'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
