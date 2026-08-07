/// Mirrors the `data` block returned by `POST /api/v1/wallet`.
class WalletBalance {
  const WalletBalance({required this.balance});

  final double balance;

  factory WalletBalance.fromJson(Map<String, dynamic> json) =>
      WalletBalance(balance: (json['balance'] as num?)?.toDouble() ?? 0);
}
