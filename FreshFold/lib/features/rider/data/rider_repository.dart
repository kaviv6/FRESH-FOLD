import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/collection_summary.dart';
import '../../../models/garment.dart';
import '../../../models/payment_session.dart';
import '../../../models/pickup.dart';

/// Wraps the rider-only `/api/v1/rider/*` endpoints. Server-side, both
/// require `group_laundry_rider` (or admin).
class RiderRepository {
  RiderRepository(this._api);
  final ApiClient _api;

  /// [state] optionally filters to one pickup state
  /// (draft/scheduled/picked/delivered/cancel).
  Future<List<PickupRequest>> getAssignedPickups({String? state}) async {
    final res = await _api.call('rider/pickups', {
      if (state != null) 'state': state,
    });
    final list = (res['data'] as List? ?? []);
    return list
        .map((e) => PickupRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// [action] must be one of: schedule, pickup, deliver, cancel. The
  /// server enforces the valid transition for the pickup's current state.
  Future<PickupRequest> performAction(int pickupId, String action) async {
    final res = await _api.call('rider/pickup/action', {
      'pickup_id': pickupId,
      'action': action,
    });
    return PickupRequest.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// Scans a garment barcode to advance its cleaning state. [targetState]
  /// must be one of cleaning/ready/delivered; the server enforces the
  /// linear received→cleaning→ready→delivered transition and rejects skips.
  Future<Garment> scanGarment(String barcode, String targetState) async {
    final res = await _api.call('garment/scan', {
      'barcode': barcode,
      'state': targetState,
    });
    return Garment.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// Records a **cash** payment collected in person from the customer
  /// (typically at delivery) — an instant bookkeeping entry, since physical
  /// cash never goes through a payment gateway. The server rejects an
  /// [amount] greater than the order's remaining balance.
  Future<void> collectPayment({
    required int pickupId,
    required double amount,
    required String method,
  }) async {
    await _api.call('rider/collect_payment', {
      'pickup_id': pickupId,
      'amount': amount,
      'method': method,
    });
  }

  /// Opens a *real* Cashfree checkout for the order's remaining balance, on
  /// the rider's phone, for the rider to hand to the customer to pay by
  /// UPI/card at the door. [method] is 'upi' or 'card' — tags the resulting
  /// transaction so it counts toward this rider's collection stat once the
  /// webhook confirms it (see laundry_management's payment_transaction.py).
  Future<PaymentSession> initiateGatewayCollection({
    required int orderId,
    required String method,
  }) async {
    final res = await _api.call('order/pay', {'order_id': orderId, 'method': method});
    return PaymentSession.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// [period] must be 'today' or 'week' — matches the Today/History stat
  /// cards.
  Future<CollectionSummary> getCollectionSummary({String period = 'today'}) async {
    final res = await _api.call('rider/collection_summary', {'period': period});
    return CollectionSummary.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepository(ref.watch(apiClientProvider));
});

final riderPickupsProvider = FutureProvider.autoDispose<List<PickupRequest>>((ref) {
  return ref.watch(riderRepositoryProvider).getAssignedPickups();
});

final riderCollectionSummaryProvider =
    FutureProvider.autoDispose.family<CollectionSummary, String>((ref, period) {
  return ref.watch(riderRepositoryProvider).getCollectionSummary(period: period);
});
