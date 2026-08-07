import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/dashboard_kpis.dart';

/// Wraps the admin-only `POST /api/v1/dashboard` KPI endpoint.
class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;

  Future<DashboardKpis> getDashboard() async {
    final res = await _api.call('dashboard');
    return DashboardKpis.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final dashboardProvider = FutureProvider.autoDispose<DashboardKpis>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});
