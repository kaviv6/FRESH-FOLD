import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/contract_request.dart';

/// Wraps `/api/v1/contract-request/*` and `/api/v1/admin/contract-request*`
/// — shared by the customer "Business Enquiry" form (create) and the Admin
/// "Business Requests" list (list + advance lifecycle), same as
/// [OrdersRepository] serves both customer and admin order screens.
class ContractRequestRepository {
  ContractRequestRepository(this._api);
  final ApiClient _api;

  Future<ContractRequest> submit({
    required String businessName,
    required String contactPerson,
    required String businessType,
    required String phone,
    String notes = '',
  }) async {
    final res = await _api.call('contract-request/create', {
      'business_name': businessName,
      'contact_person': contactPerson,
      'business_type': businessType,
      'phone': phone,
      'notes': notes,
    });
    return ContractRequest.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// Admin: list every request, optionally filtered to one [state]
  /// (submitted/in_negotiation/converted/cancel).
  Future<List<ContractRequest>> getAll({String? state}) async {
    final res = await _api.call('admin/contract-requests', {
      if (state != null) 'state': state,
    });
    final list = (res['data'] as List? ?? []);
    return list.map((e) => ContractRequest.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Admin: [action] must be one of negotiate/convert/cancel. The server
  /// enforces the valid transition for the request's current state.
  Future<ContractRequest> performAction(int requestId, String action) async {
    final res = await _api.call('admin/contract-request/action', {
      'request_id': requestId,
      'action': action,
    });
    return ContractRequest.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final contractRequestRepositoryProvider = Provider<ContractRequestRepository>((ref) {
  return ContractRequestRepository(ref.watch(apiClientProvider));
});

/// Customer submit form only needs the repository (fire-and-forget submit +
/// a confirmation dialog) — no list provider needed there.
final adminContractRequestsProvider = FutureProvider.autoDispose<List<ContractRequest>>((ref) {
  return ref.watch(contractRequestRepositoryProvider).getAll();
});
