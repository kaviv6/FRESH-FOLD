import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/garment.dart';

/// Wraps `POST /api/v1/garment/list` — per-item cleaning status for an
/// order's garments. The rider-side `garment/scan` endpoint is wrapped
/// separately by `RiderRepository`.
class GarmentRepository {
  GarmentRepository(this._api);
  final ApiClient _api;

  Future<List<Garment>> getGarments(int orderId) async {
    final res = await _api.call('garment/list', {'order_id': orderId});
    final list = (res['data'] as List? ?? []);
    return list
        .map((e) => Garment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

final garmentRepositoryProvider = Provider<GarmentRepository>((ref) {
  return GarmentRepository(ref.watch(apiClientProvider));
});

final garmentsForOrderProvider =
    FutureProvider.autoDispose.family<List<Garment>, int>((ref, orderId) {
  return ref.watch(garmentRepositoryProvider).getGarments(orderId);
});
