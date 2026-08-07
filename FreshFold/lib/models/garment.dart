/// Mirrors one entry of the `POST /api/v1/garment/list` response.
/// States: received, cleaning, ready, delivered.
class Garment {
  const Garment({
    required this.id,
    required this.name,
    required this.barcode,
    required this.serviceType,
    required this.qty,
    required this.state,
    required this.notes,
  });

  final int id;
  final String name;
  final String barcode;
  final String? serviceType;
  final int qty;
  final String state;
  final String notes;

  factory Garment.fromJson(Map<String, dynamic> json) => Garment(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        serviceType: json['service_type'] as String?,
        qty: (json['qty'] as num?)?.toInt() ?? 1,
        state: json['state'] as String? ?? 'received',
        notes: json['notes'] as String? ?? '',
      );
}
