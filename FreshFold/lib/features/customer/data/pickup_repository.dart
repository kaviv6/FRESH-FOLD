import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/pickup.dart';

/// Wraps the customer-facing `/api/v1/pickup/*` endpoints. Like
/// [OrdersRepository], `pickup/list` and `pickup/details` are
/// role-agnostic server-side (admins see every pickup), so the Admin "All
/// Pickups" screen reuses this too.
class PickupRepository {
  PickupRepository(this._api);
  final ApiClient _api;

  Future<List<PickupRequest>> getPickups() async {
    final res = await _api.call('pickup/list');
    final list = (res['data'] as List? ?? []);
    return list
        .map((e) => PickupRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PickupRequest> getPickupDetails(int pickupId) async {
    final res = await _api.call('pickup/details', {'pickup_id': pickupId});
    return PickupRequest.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// [scheduleDate] must be `'yyyy-MM-dd HH:mm:ss'` (Odoo Datetime format,
  /// UTC).
  Future<PickupRequest> createPickup({
    required String scheduleDate,
    required List<Map<String, dynamic>> lines,
    String paymentMethod = 'cod',
  }) async {
    final res = await _api.call('pickup/create', {
      'schedule_date': scheduleDate,
      'lines': lines,
      'payment_method': paymentMethod,
    });
    return PickupRequest.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final pickupRepositoryProvider = Provider<PickupRepository>((ref) {
  return PickupRepository(ref.watch(apiClientProvider));
});

final pickupsListProvider = FutureProvider.autoDispose<List<PickupRequest>>((ref) {
  return ref.watch(pickupRepositoryProvider).getPickups();
});

final pickupDetailsProvider =
    FutureProvider.autoDispose.family<PickupRequest, int>((ref, pickupId) {
  return ref.watch(pickupRepositoryProvider).getPickupDetails(pickupId);
});
