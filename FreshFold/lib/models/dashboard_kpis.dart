/// Mirrors one entry of `rider_stats` in the `/api/v1/dashboard` response.
class RiderStat {
  const RiderStat({
    required this.riderId,
    required this.name,
    required this.deliveredTotal,
    required this.activePickups,
  });

  final int riderId;
  final String name;
  final int deliveredTotal;
  final int activePickups;

  factory RiderStat.fromJson(Map<String, dynamic> json) => RiderStat(
        riderId: json['rider_id'] as int,
        name: json['name'] as String? ?? '',
        deliveredTotal: (json['delivered_total'] as num?)?.toInt() ?? 0,
        activePickups: (json['active_pickups'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors the `data` block returned by `POST /api/v1/dashboard` (admin-only).
class DashboardKpis {
  const DashboardKpis({
    required this.revenueThisMonth,
    required this.draftOrders,
    required this.confirmedOrders,
    required this.activePickups,
    required this.deliveredToday,
    required this.avgRating,
    required this.totalRatings,
    required this.riderStats,
  });

  final double revenueThisMonth;
  final int draftOrders;
  final int confirmedOrders;
  final int activePickups;
  final int deliveredToday;
  final double avgRating;
  final int totalRatings;
  final List<RiderStat> riderStats;

  int get ridersActive => riderStats.where((r) => r.activePickups > 0).length;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) => DashboardKpis(
        revenueThisMonth: (json['revenue_this_month'] as num?)?.toDouble() ?? 0,
        draftOrders: (json['draft_orders'] as num?)?.toInt() ?? 0,
        confirmedOrders: (json['confirmed_orders'] as num?)?.toInt() ?? 0,
        activePickups: (json['active_pickups'] as num?)?.toInt() ?? 0,
        deliveredToday: (json['delivered_today'] as num?)?.toInt() ?? 0,
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
        totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
        riderStats: (json['rider_stats'] as List? ?? [])
            .map((e) => RiderStat.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
