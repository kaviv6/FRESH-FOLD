import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/wallet.dart';

/// Wraps the customer-facing wallet endpoints. `wallet/topup` is admin-only
/// server-side (a customer's balance is credited after an online payment
/// confirms — see ROADMAP.md D4) so it isn't exposed here.
class WalletRepository {
  WalletRepository(this._api);
  final ApiClient _api;

  Future<WalletBalance> getBalance() async {
    final res = await _api.call('wallet');
    return WalletBalance.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// Pays an order's full total from the customer's wallet balance. Throws
  /// [ApiException] on insufficient balance or an ineligible order state —
  /// the server is the source of truth.
  Future<void> payOrder(int orderId) async {
    await _api.call('wallet/pay', {'order_id': orderId});
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

final walletBalanceProvider = FutureProvider.autoDispose<WalletBalance>((ref) {
  return ref.watch(walletRepositoryProvider).getBalance();
});
