import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/service_type.dart';

/// `POST /api/v1/services` — the read-only service type catalog with
/// prices. Used by Services & Pricing, Book Pickup, and the Admin pricing
/// list (there is no admin write endpoint yet, see ROADMAP.md).
class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<List<ServiceType>> getServices() async {
    final res = await _api.call('services');
    final list = (res['data'] as List? ?? []);
    return list
        .map((e) => ServiceType.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

final servicesProvider = FutureProvider<List<ServiceType>>((ref) {
  return ref.watch(catalogRepositoryProvider).getServices();
});
