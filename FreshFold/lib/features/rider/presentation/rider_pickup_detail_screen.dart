import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_field_decoration.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/pickup.dart';
import '../data/rider_repository.dart';

/// Rider — Pickup Detail (design screen 15). Mounted at
/// `/rider/pickups/:id`. The primary CTA and its wired action are dynamic
/// based on `pickup.state`:
///   scheduled -> "Mark as Picked Up" (action: pickup)
///   picked    -> "Mark as Delivered" (action: deliver)
///   otherwise -> no primary CTA (already terminal)
/// "Cancel Pickup" is shown unless the pickup is already delivered/cancelled.
class RiderPickupDetailScreen extends ConsumerStatefulWidget {
  const RiderPickupDetailScreen({super.key, required this.pickupId});

  final int pickupId;

  @override
  ConsumerState<RiderPickupDetailScreen> createState() => _RiderPickupDetailScreenState();
}

class _RiderPickupDetailScreenState extends ConsumerState<RiderPickupDetailScreen> {
  // Local override so the screen reflects a just-performed action
  // immediately, without needing a dedicated per-id detail provider.
  PickupRequest? _override;
  bool _actionLoading = false;

  Future<void> _runAction(String action) async {
    setState(() => _actionLoading = true);
    try {
      final updated =
          await ref.read(riderRepositoryProvider).performAction(widget.pickupId, action);
      ref.invalidate(riderPickupsProvider);
      if (mounted) setState(() => _override = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel pickup?'),
        content: const Text('This will cancel the pickup request. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes, cancel', style: TextStyle(color: AppColors.redText)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runAction('cancel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupsAsync = ref.watch(riderPickupsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: AsyncValueView<List<PickupRequest>>(
          value: pickupsAsync,
          onRetry: () => ref.invalidate(riderPickupsProvider),
          data: (context, pickups) {
            PickupRequest? found;
            for (final p in pickups) {
              if (p.id == widget.pickupId) {
                found = p;
                break;
              }
            }
            final pickup = _override ?? found;
            if (pickup == null) {
              return Center(
                child: Text('Pickup not found.', style: AppText.body(AppColors.muted400)),
              );
            }
            return _DetailBody(
              pickup: pickup,
              actionLoading: _actionLoading,
              onPrimaryAction: _runAction,
              onCancel: _confirmCancel,
              onPaymentCollected: () {
                ref.invalidate(riderPickupsProvider);
                ref.invalidate(riderCollectionSummaryProvider('today'));
                ref.invalidate(riderCollectionSummaryProvider('week'));
                setState(() => _override = null);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.pickup,
    required this.actionLoading,
    required this.onPrimaryAction,
    required this.onCancel,
    required this.onPaymentCollected,
  });

  final PickupRequest pickup;
  final bool actionLoading;
  final ValueChanged<String> onPrimaryAction;
  final VoidCallback onCancel;
  final VoidCallback onPaymentCollected;

  String get _initials {
    final parts = pickup.customer.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  String get _paymentLabel {
    switch (pickup.paymentMethod) {
      case 'cod':
        return 'COD';
      case 'online':
        return 'Online';
      case 'wallet':
        return 'Wallet';
      default:
        return pickup.paymentMethod;
    }
  }

  (String label, String action)? get _primaryAction {
    switch (pickup.state) {
      case 'scheduled':
        return ('Mark as Picked Up', 'pickup');
      case 'picked':
        return ('Mark as Delivered', 'deliver');
      default:
        return null;
    }
  }

  bool get _isTerminal => pickup.state == 'delivered' || pickup.state == 'cancel' || pickup.state == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final primary = _primaryAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.ink900),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              Text(pickup.name, style: AppText.h1(AppColors.ink900).copyWith(fontSize: 18)),
              const Spacer(),
              StatusPill(label: stateLabel(pickup.state), state: pickup.state),
              const SizedBox(width: 12),
              const LogoutButton(),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer info card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.blueChipBg,
                          shape: BoxShape.circle,
                        ),
                        child: Text(_initials, style: AppText.bodySmallBold(AppColors.blueChipText).copyWith(fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pickup.customer, style: AppText.bodyBold(AppColors.ink900)),
                            const SizedBox(height: 2),
                            Text(
                              'Customer · $_paymentLabel ${formatMoney(pickup.totalAmount)}',
                              style: AppText.caption(AppColors.muted500).copyWith(fontSize: 11.5, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Phone number not available')),
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.greenChipBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_outlined, size: 17, color: AppColors.greenChipText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Address card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_outlined, size: 17, color: AppColors.coral),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pickup.address.singleLine,
                              style: AppText.bodySmall(AppColors.ink700).copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(pickup.address.googleMapsUrl);
                          final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open Google Maps.')),
                            );
                          }
                        },
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.navigation_outlined, size: 15, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Navigate with Google Maps', style: AppText.bodySmallBold(Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text('Items to collect', style: AppText.bodySmallBold(AppColors.ink700)),
                const SizedBox(height: 8),
                for (final line in pickup.lines ?? [])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${line.serviceType ?? line.product} × ${line.quantity}',
                          style: AppText.bodySmall(AppColors.ink600),
                        ),
                        Text(formatMoney(line.subtotal), style: AppText.bodySmallBold(AppColors.ink700)),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pickup.paymentStatus == 'paid' ? 'Paid' : 'Amount Due',
                        style: AppText.bodyBold(AppColors.ink900),
                      ),
                      Text(
                        formatMoney(pickup.paymentStatus == 'paid' ? pickup.totalAmount : pickup.amountDue),
                        style: AppText.h2(AppColors.ink900).copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                if (pickup.orderId != null &&
                    pickup.amountDue > 0 &&
                    pickup.state != 'cancel' &&
                    pickup.state != 'cancelled') ...[
                  const SizedBox(height: 12),
                  _CollectPaymentButton(pickup: pickup, onCollected: onPaymentCollected),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (primary != null)
                PrimaryButton(
                  label: primary.$1,
                  color: AppColors.coral,
                  loading: actionLoading,
                  onPressed: () => onPrimaryAction(primary.$2),
                ),
              if (primary != null && !_isTerminal) const SizedBox(height: 10),
              if (!_isTerminal)
                Center(
                  child: TextButton(
                    onPressed: actionLoading ? null : onCancel,
                    child: Text('Cancel Pickup', style: AppText.bodySmallBold(AppColors.redText)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectPaymentButton extends StatelessWidget {
  const _CollectPaymentButton({required this.pickup, required this.onCollected});

  final PickupRequest pickup;
  final VoidCallback onCollected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _CollectPaymentSheet(pickup: pickup, onCollected: onCollected),
        ),
        icon: const Icon(Icons.payments_outlined, size: 18, color: AppColors.coral),
        label: Text('Collect Payment', style: AppText.bodySmallBold(AppColors.coral)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.coral, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Lets the rider record a payment collected in person from the customer.
///
/// - **Cash**: an instant bookkeeping entry via `/api/v1/rider/collect_payment`
///   — physical cash never goes through a gateway, so there's nothing to
///   verify; it feeds straight into `laundry.order._register_payment()`.
/// - **UPI / Card**: opens a *real* Cashfree checkout (same SDK flow as the
///   customer's own Pay Online) on the rider's phone, for the rider to hand
///   to the customer to complete. Only Cashfree's webhook confirming the
///   transaction actually marks it paid — this screen just submits it and
///   waits, same as the customer app does.
class _CollectPaymentSheet extends ConsumerStatefulWidget {
  const _CollectPaymentSheet({required this.pickup, required this.onCollected});

  final PickupRequest pickup;
  final VoidCallback onCollected;

  @override
  ConsumerState<_CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends ConsumerState<_CollectPaymentSheet> {
  late final TextEditingController _amountCtrl;
  final _cfPaymentGatewayService = CFPaymentGatewayService();
  String _method = 'cash';
  bool _submitting = false;

  bool get _isGateway => _method == 'upi' || _method == 'card';

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.pickup.amountDue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _selectMethod(String method) {
    setState(() {
      _method = method;
      // Cashfree charges exactly the order's remaining balance — only cash
      // (counted by hand) supports collecting a partial amount.
      if (method != 'cash') {
        _amountCtrl.text = widget.pickup.amountDue.toStringAsFixed(2);
      }
    });
  }

  Future<void> _submit() async {
    if (_isGateway) {
      await _submitGateway();
    } else {
      await _submitCash();
    }
  }

  Future<void> _submitCash() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (amount > widget.pickup.amountDue + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds the remaining due (${formatMoney(widget.pickup.amountDue)})',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(riderRepositoryProvider).collectPayment(
            pickupId: widget.pickup.id,
            amount: amount,
            method: _method,
          );
      widget.onCollected();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Collected ${formatMoney(amount)}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitGateway() async {
    final orderId = widget.pickup.orderId;
    if (orderId == null) return;
    setState(() => _submitting = true);
    try {
      final session = await ref.read(riderRepositoryProvider).initiateGatewayCollection(
            orderId: orderId,
            method: _method,
          );
      final cfSession = CFSessionBuilder()
          .setEnvironment(session.isSandbox ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION)
          .setOrderId(session.cashfreeOrderId)
          .setPaymentSessionId(session.paymentSessionId)
          .build();
      final cfWebCheckout = CFWebCheckoutPaymentBuilder().setSession(cfSession).build();
      _cfPaymentGatewayService.setCallback(_onGatewayVerify, _onGatewayError);
      _cfPaymentGatewayService.doPayment(cfWebCheckout);
    } on CFException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _submitting = false);
    }
  }

  void _onGatewayVerify(String cashfreeOrderId) {
    widget.onCollected();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment submitted — refreshing order status')),
    );
  }

  void _onGatewayError(CFErrorResponse error, String cashfreeOrderId) {
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.getMessage() ?? 'Payment failed')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Collect Payment', style: AppText.h2(AppColors.ink900).copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            'Remaining due: ${formatMoney(widget.pickup.amountDue)}',
            style: AppText.caption(AppColors.muted500),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            enabled: !_isGateway,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: appFieldDecoration(hint: 'Amount'),
          ),
          if (_isGateway)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'UPI/Card opens a real payment gateway for the full remaining amount.',
                style: AppText.caption(AppColors.muted450),
              ),
            ),
          const SizedBox(height: 14),
          Text('Method', style: AppText.bodySmallBold(AppColors.ink700)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final m in const [('cash', 'Cash'), ('upi', 'UPI'), ('card', 'Card')])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m.$2),
                      selected: _method == m.$1,
                      onSelected: (_) => _selectMethod(m.$1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _isGateway ? 'Open Payment Gateway' : 'Confirm Collection',
            color: AppColors.coral,
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
