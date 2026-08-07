import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/payment_session.dart';

/// Wraps `POST /api/v1/order/pay`, which creates a `payment.transaction`
/// server-side against Cashfree and returns a session for the Flutter SDK.
class PaymentRepository {
  PaymentRepository(this._api);
  final ApiClient _api;

  Future<PaymentSession> initiatePayment(int orderId) async {
    final res = await _api.call('order/pay', {'order_id': orderId});
    return PaymentSession.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});
