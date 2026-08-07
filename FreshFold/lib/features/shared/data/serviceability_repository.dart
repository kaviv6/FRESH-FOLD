import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

/// Mirrors the `data` block returned by `POST /api/v1/serviceable`.
class ServiceabilityResult {
  const ServiceabilityResult({required this.serviceable, required this.message, this.zone});

  final bool serviceable;
  final String message;
  final String? zone;

  factory ServiceabilityResult.fromJson(Map<String, dynamic> json) => ServiceabilityResult(
        serviceable: json['serviceable'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        zone: json['zone'] as String?,
      );
}

/// Wraps `/api/v1/serviceable` (`auth='none'` server-side — callable before
/// login too, e.g. from a future signup address step).
class ServiceabilityRepository {
  ServiceabilityRepository(this._api);
  final ApiClient _api;

  Future<ServiceabilityResult> check({String? zip, String? city}) async {
    final res = await _api.call('serviceable', {
      if (zip != null && zip.isNotEmpty) 'zip': zip,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    return ServiceabilityResult.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final serviceabilityRepositoryProvider = Provider<ServiceabilityRepository>((ref) {
  return ServiceabilityRepository(ref.watch(apiClientProvider));
});
