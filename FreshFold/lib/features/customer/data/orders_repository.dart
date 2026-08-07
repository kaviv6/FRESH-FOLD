import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/order.dart';
import '../../../models/order_rating.dart';

/// Wraps the `/api/v1/orders*` endpoints. `getOrders`/`getOrderDetails`
/// are role-agnostic on the server: a customer sees only their own orders,
/// an admin sees every order (see `_is_admin` in api_controller.py) — so
/// this one repository serves both the customer "My Orders" tab and the
/// Admin "All Orders" screen.
class OrdersRepository {
  OrdersRepository(this._api);
  final ApiClient _api;

  Future<List<LaundryOrder>> getOrders() async {
    final res = await _api.call('orders');
    final list = (res['data'] as List? ?? []);
    return list
        .map((e) => LaundryOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<LaundryOrder> getOrderDetails(int orderId) async {
    final res = await _api.call('order/details', {'order_id': orderId});
    return LaundryOrder.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// Raw PDF bytes for the order's tax invoice. Throws [ApiException] (e.g.
  /// "Invoice not generated yet") if the order hasn't been invoiced.
  Future<List<int>> downloadInvoicePdf(int orderId) {
    return _api.downloadBytes('order/$orderId/invoice/pdf');
  }

  Future<LaundryOrder> createOrder({
    required List<Map<String, dynamic>> lines,
    String paymentMethod = 'cod',
    String? note,
  }) async {
    final res = await _api.call('order/create', {
      'lines': lines,
      'payment_method': paymentMethod,
      if (note != null) 'note': note,
    });
    return LaundryOrder.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<void> cancelOrder(int orderId) async {
    await _api.call('order/cancel', {'order_id': orderId});
  }

  /// [newState] must be one of draft/order/cancel — 'invoiced' can only be
  /// set server-side via the invoicing flow, per `VALID_ORDER_STATES`.
  Future<void> updateStatus(int orderId, String newState) async {
    await _api.call('order/update_status', {'order_id': orderId, 'state': newState});
  }

  /// Applies a promo code to a draft order. Throws [ApiException] (e.g. code
  /// invalid/expired, order not draft, or a promo already applied) — the
  /// server is the source of truth for eligibility.
  Future<void> applyPromo(int orderId, String code) async {
    await _api.call('order/apply_promo', {'order_id': orderId, 'code': code});
  }

  Future<OrderRating> getRating(int orderId) async {
    final res = await _api.call('order/rating', {'order_id': orderId});
    return OrderRating.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// [rating] must be 1-5. Only allowed once an order is `invoiced`
  /// (server-enforced).
  Future<void> rateOrder(int orderId, int rating, {String? review}) async {
    await _api.call('order/rate', {
      'order_id': orderId,
      'rating': rating,
      if (review != null && review.isNotEmpty) 'review': review,
    });
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

final ordersListProvider = FutureProvider.autoDispose<List<LaundryOrder>>((ref) {
  return ref.watch(ordersRepositoryProvider).getOrders();
});

final orderDetailsProvider =
    FutureProvider.autoDispose.family<LaundryOrder, int>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).getOrderDetails(orderId);
});

final orderRatingProvider =
    FutureProvider.autoDispose.family<OrderRating, int>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).getRating(orderId);
});
