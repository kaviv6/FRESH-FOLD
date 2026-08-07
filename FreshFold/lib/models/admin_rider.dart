/// Mirrors one entry of the `POST /api/v1/admin/riders` response — used by
/// the admin "Assign Rider" picker.
class AdminRider {
  const AdminRider({
    required this.id,
    required this.name,
    required this.activePickups,
  });

  final int id;
  final String name;
  final int activePickups;

  factory AdminRider.fromJson(Map<String, dynamic> json) => AdminRider(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        activePickups: (json['active_pickups'] as num?)?.toInt() ?? 0,
      );
}
