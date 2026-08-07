import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/admin_rider.dart';
import '../../../models/pickup.dart';

/// Wraps the admin-only `/api/v1/admin/*` rider-assignment endpoints.
class AdminRiderRepository {
  AdminRiderRepository(this._api);
  final ApiClient _api;

  Future<List<AdminRider>> getRiders() async {
    final res = await _api.call('admin/riders');
    final list = (res['data'] as List? ?? []);
    return list
        .map((e) => AdminRider.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Assigns [riderId] to [pickupId]. A pickup still in `draft` is
  /// automatically moved to `scheduled` by the server.
  Future<PickupRequest> assignRider({required int pickupId, required int riderId}) async {
    final res = await _api.call('admin/pickup/assign_rider', {
      'pickup_id': pickupId,
      'rider_id': riderId,
    });
    return PickupRequest.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final adminRiderRepositoryProvider = Provider<AdminRiderRepository>((ref) {
  return AdminRiderRepository(ref.watch(apiClientProvider));
});

final adminRidersListProvider = FutureProvider.autoDispose<List<AdminRider>>((ref) {
  return ref.watch(adminRiderRepositoryProvider).getRiders();
});
