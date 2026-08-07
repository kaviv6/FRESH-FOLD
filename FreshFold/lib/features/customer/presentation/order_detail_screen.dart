import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_field_decoration.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/order.dart';
import '../data/orders_repository.dart';
import '../data/payment_repository.dart';
import '../data/wallet_repository.dart';
import 'garment_tracking_screen.dart';
import 'order_rating_sheet.dart';

String _paymentLabel(String method) {
  switch (method) {
    case 'online':
      return 'Online Payment';
    case 'wallet':
      return 'Wallet';
    case 'cod':
    default:
      return 'Cash on Delivery';
  }
}

/// Screen 11 · Order Detail (Invoiced). Route: `/customer/orders/:id`.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final title = orderAsync.asData?.value.name ?? 'Order';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DetailAppBar(title: title, trailing: const LogoutButton()),
      body: AsyncValueView<LaundryOrder>(
        value: orderAsync,
        data: (context, order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order});
  final LaundryOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StatusPill(label: stateLabel(order.state), state: order.state),
                  if (order.isExpress) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.coralChipBg, borderRadius: BorderRadius.circular(100)),
                      child: Text('EXPRESS', style: AppText.microBold(AppColors.coralChipText)),
                    ),
                  ],
                ],
              ),
              Text(formatDate(order.orderDate), style: AppText.caption(AppColors.muted450)),
            ],
          ),
          if (order.garmentCount > 0) ...[
            const SizedBox(height: 10),
            _GarmentTrackingRow(order: order),
          ],
          const SizedBox(height: 18),
          Text('Items', style: AppText.bodySmallBold(AppColors.ink700)),
          const SizedBox(height: 10),
          for (final line in order.lines ?? const [])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${line.serviceType ?? line.product} × ${line.quantity}', style: AppText.body(AppColors.ink600)),
                  Text(formatMoney(line.subtotal), style: AppText.bodySmallBold(AppColors.ink900).copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment method', style: AppText.body(AppColors.muted450)),
                Text(_paymentLabel(order.paymentMethod), style: AppText.bodySmallBold(AppColors.ink700).copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (order.promoDiscount > 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: AppText.body(AppColors.muted450)),
                  Text(formatMoney(order.subtotal), style: AppText.body(AppColors.ink700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Promo · ${order.promoCode}', style: AppText.body(AppColors.tealText)),
                  Text('− ${formatMoney(order.promoDiscount)}', style: AppText.bodySmallBold(AppColors.tealText)),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppText.bodyBold(AppColors.ink900)),
                Text(formatMoney(order.totalAmount), style: AppText.h2(AppColors.ink900).copyWith(fontSize: 15)),
              ],
            ),
          ),
          // Promo/cancel only apply to a draft order, but the ability to
          // pay is independent of order state — an already-invoiced
          // (COD-delivered) order can still have a balance due if the rider
          // never actually collected it, and the customer should be able to
          // settle that from here too.
          if (order.state != 'cancel' && (order.state == 'draft' || order.paymentStatus != 'paid'))
            _DraftOrderActions(order: order),
          if (order.state == 'invoiced') ...[
            _InvoiceCard(order: order),
            const SizedBox(height: 14),
            OrderRatingSection(orderId: order.id),
          ],
        ],
      ),
    );
  }
}

class _GarmentTrackingRow extends StatelessWidget {
  const _GarmentTrackingRow({required this.order});
  final LaundryOrder order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GarmentTrackingScreen(orderId: order.id, orderName: order.name)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.tealChipBg.withOpacity(0.4),
            border: Border.all(color: AppColors.tealChipBg),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.checkroom_outlined, size: 18, color: AppColors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Track ${order.garmentCount} garment${order.garmentCount == 1 ? '' : 's'}',
                  style: AppText.bodySmallBold(AppColors.tealTextStrong),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}

/// Promo code entry + cancel action for a `draft` order. Neither had any UI
/// entry point before — `applyPromo`/`cancelOrder` existed in
/// [OrdersRepository] but no screen called them.
class _DraftOrderActions extends ConsumerStatefulWidget {
  const _DraftOrderActions({required this.order});
  final LaundryOrder order;

  @override
  ConsumerState<_DraftOrderActions> createState() => _DraftOrderActionsState();
}

class _DraftOrderActionsState extends ConsumerState<_DraftOrderActions> {
  final _promoCtrl = TextEditingController();
  final _cfPaymentGatewayService = CFPaymentGatewayService();
  bool _applyingPromo = false;
  bool _cancelling = false;
  bool _payingWithWallet = false;
  bool _payingOnline = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _applyingPromo = true);
    try {
      await ref.read(ordersRepositoryProvider).applyPromo(widget.order.id, code);
      ref.invalidate(orderDetailsProvider(widget.order.id));
      _promoCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promo code applied')));
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not apply promo code.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _applyingPromo = false);
    }
  }

  /// The Cashfree order/session comes from `POST /api/v1/order/pay`.
  /// Verification of the actual payment outcome happens server-side via
  /// Cashfree's webhook (see ROADMAP.md D3b) — [_onPaymentVerify] just
  /// refreshes the order so the customer sees the updated state once that
  /// lands, rather than trusting the client-side callback as truth.
  Future<void> _payOnline() async {
    setState(() => _payingOnline = true);
    try {
      final session = await ref.read(paymentRepositoryProvider).initiatePayment(widget.order.id);
      final cfSession = CFSessionBuilder()
          .setEnvironment(session.isSandbox ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION)
          .setOrderId(session.cashfreeOrderId)
          .setPaymentSessionId(session.paymentSessionId)
          .build();
      final cfWebCheckout = CFWebCheckoutPaymentBuilder().setSession(cfSession).build();
      _cfPaymentGatewayService.setCallback(_onPaymentVerify, _onPaymentError);
      _cfPaymentGatewayService.doPayment(cfWebCheckout);
    } on CFException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not start online payment.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _payingOnline = false);
    }
  }

  void _onPaymentVerify(String cashfreeOrderId) {
    ref.invalidate(orderDetailsProvider(widget.order.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment submitted — refreshing order status')),
    );
  }

  void _onPaymentError(CFErrorResponse error, String cashfreeOrderId) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.getMessage() ?? 'Payment failed')));
  }

  Future<void> _payWithWallet() async {
    setState(() => _payingWithWallet = true);
    try {
      await ref.read(walletRepositoryProvider).payOrder(widget.order.id);
      ref.invalidate(orderDetailsProvider(widget.order.id));
      ref.invalidate(walletBalanceProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paid from wallet')));
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not pay from wallet.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _payingWithWallet = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep order')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cancel order', style: TextStyle(color: AppColors.redText)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(widget.order.id);
      ref.invalidate(orderDetailsProvider(widget.order.id));
      ref.invalidate(ordersListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not cancel order.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.order.state == 'draft' && widget.order.promoCode == null) ...[
          Text('Promo code', style: AppText.bodySmallBold(AppColors.ink700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: appFieldDecoration(hint: 'Enter code'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _applyingPromo ? null : _applyPromo,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.teal, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _applyingPromo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                        )
                      : Text('Apply', style: AppText.bodyBold(AppColors.teal)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        if (widget.order.paymentStatus == 'paid') ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.tealChipBg.withOpacity(0.4),
              border: Border.all(color: AppColors.tealChipBg),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: AppColors.teal),
                const SizedBox(width: 8),
                Text('Paid in full', style: AppText.bodySmallBold(AppColors.tealTextStrong)),
              ],
            ),
          ),
        ] else ...[
          if (widget.order.paymentStatus == 'partial')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${formatMoney(widget.order.amountPaid)} paid · ${formatMoney(widget.order.amountDue)} remaining',
                style: AppText.caption(AppColors.muted500),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Pay ${formatMoney(widget.order.amountDue)} Online',
                icon: Icons.credit_card_outlined,
                loading: _payingOnline,
                onPressed: _payOnline,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final walletAsync = ref.watch(walletBalanceProvider);
              final balance = walletAsync.asData?.value.balance;
              final canPay = balance != null && balance >= widget.order.amountDue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: balance != null
                        ? 'Pay ${formatMoney(widget.order.amountDue)} with Wallet (bal. ${formatMoney(balance)})'
                        : 'Pay with Wallet',
                    loading: _payingWithWallet,
                    onPressed: canPay ? _payWithWallet : null,
                  ),
                ),
              );
            },
          ),
        ],
        if (widget.order.state == 'draft')
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Cancel Order',
              color: AppColors.redText,
              loading: _cancelling,
              onPressed: _cancelOrder,
            ),
          ),
      ],
    );
  }
}

class _InvoiceCard extends ConsumerStatefulWidget {
  const _InvoiceCard({required this.order});
  final LaundryOrder order;

  @override
  ConsumerState<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends ConsumerState<_InvoiceCard> {
  bool _downloading = false;
  bool _sharing = false;

  /// Fetches the PDF and writes it to a temp file, shared by both actions.
  Future<File> _fetchToTempFile() async {
    final bytes = await ref.read(ordersRepositoryProvider).downloadInvoicePdf(widget.order.id);
    final dir = await getTemporaryDirectory();
    final filename = 'Invoice-${widget.order.name.replaceAll('/', '-')}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final file = await _fetchToTempFile();
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message.isNotEmpty ? result.message : 'Could not open the invoice.')));
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not download the invoice.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final file = await _fetchToTempFile();
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice for order ${widget.order.name}');
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not share the invoice.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgScreen,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 20, color: AppColors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tax invoice', style: AppText.bodySmallBold(AppColors.ink900)),
                    Text('Available once generated', style: AppText.caption(AppColors.muted450).copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _downloading ? null : _download,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    icon: _downloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_outlined, size: 15, color: Colors.white),
                    label: Text('Download', style: AppText.caption(Colors.white).copyWith(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: _sharing ? null : _share,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    icon: _sharing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink600),
                          )
                        : const Icon(Icons.ios_share_outlined, size: 15, color: AppColors.ink600),
                    label: Text('Share', style: AppText.caption(AppColors.ink600).copyWith(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
