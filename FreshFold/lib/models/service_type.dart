/// Mirrors `service.type` / the `/api/v1/services` response.
class ServiceType {
  const ServiceType({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final double price;

  factory ServiceType.fromJson(Map<String, dynamic> json) => ServiceType(
        id: json['id'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
      );
}
