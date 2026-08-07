/// Mirrors the `data` block returned by `POST /api/v1/order/pay` — a
/// Cashfree order + session, ready to hand to the `flutter_cashfree_pg_sdk`
/// checkout.
class PaymentSession {
  const PaymentSession({
    required this.paymentSessionId,
    required this.cashfreeOrderId,
    required this.txnEnv,
    required this.amount,
  });

  final String paymentSessionId;
  final String cashfreeOrderId;

  /// `"sandbox"` or `"production"` — selects `CFEnvironment` for the SDK.
  final String txnEnv;
  final double amount;

  bool get isSandbox => txnEnv == 'sandbox';

  factory PaymentSession.fromJson(Map<String, dynamic> json) => PaymentSession(
        paymentSessionId: json['payment_session_id'] as String,
        cashfreeOrderId: json['cashfree_order_id'] as String,
        txnEnv: json['txn_env'] as String? ?? 'sandbox',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}
