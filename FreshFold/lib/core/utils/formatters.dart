import 'package:intl/intl.dart';

/// ₹ currency, no decimals for whole numbers — matches the design's
/// "₹80" / "₹1,240" style.
String formatMoney(num amount) {
  final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: amount % 1 == 0 ? 0 : 2);
  return f.format(amount);
}

/// "Today, 11:20 AM" / "Jun 28, 4:10 PM" style used across order/pickup rows.
String formatRelativeDateTime(DateTime? dt) {
  if (dt == null) return '—';
  final local = dt.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
  final time = DateFormat('h:mm a').format(local);
  if (isToday) return 'Today, $time';
  return '${DateFormat('MMM d').format(local)}, $time';
}

String formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('MMM d, yyyy').format(dt.toLocal());
}
