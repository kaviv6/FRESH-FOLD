import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/pill_filter_row.dart';
import '../../../models/contract_request.dart';
import '../../shared/data/contract_request_repository.dart';

/// Screen 21 · Admin · Business Requests. Backed by
/// `/api/v1/admin/contract-requests` (list) and
/// `/api/v1/admin/contract-request/action` (negotiate/convert/cancel) — the
/// same `laundry.contract.request` records the customer "Business Enquiry"
/// form creates in Odoo.
class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  String _filter = 'New';

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminContractRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Business Requests', style: AppText.h1(AppColors.ink900)),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView<List<ContractRequest>>(
                value: requestsAsync,
                onRetry: () => ref.invalidate(adminContractRequestsProvider),
                data: (context, requests) {
                  final newCount = requests.where((r) => r.state == 'submitted').length;
                  final options = ['New ($newCount)', 'Negotiation', 'Converted'];
                  final selectedOption = _filter == 'New' ? options[0] : _filter;

                  List<ContractRequest> filtered;
                  switch (_filter) {
                    case 'Negotiation':
                      filtered = requests.where((r) => r.state == 'in_negotiation').toList();
                      break;
                    case 'Converted':
                      filtered = requests.where((r) => r.state == 'converted').toList();
                      break;
                    default:
                      filtered = requests.where((r) => r.state == 'submitted').toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: PillFilterRow(
                          options: options,
                          selected: selectedOption,
                          onSelected: (opt) => setState(() => _filter = opt.startsWith('New') ? 'New' : opt),
                          accentColor: AppColors.purple,
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text('No requests here yet', style: AppText.bodySmall(AppColors.muted450)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) => _RequestCard(request: filtered[i]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `StatusPill`/`AppColors.statusChip` don't know about contract-request
/// states (submitted/in_negotiation/converted) since those aren't
/// order/pickup states — mapped locally here per the design's colors
/// (blue for Submitted, coral for Negotiation, green for Converted).
(Color bg, Color fg) _contractStatusColors(String state) {
  switch (state) {
    case 'submitted':
      return (AppColors.blueChipBg, AppColors.blueChipText);
    case 'in_negotiation':
      return (AppColors.coralChipBg, AppColors.coralChipText);
    case 'converted':
      return (AppColors.greenChipBg, AppColors.greenChipText);
    default:
      return (AppColors.chipNeutralBg, AppColors.muted500);
  }
}

String _contractStateLabel(String state) {
  switch (state) {
    case 'submitted':
      return 'Submitted';
    case 'in_negotiation':
      return 'Negotiation';
    case 'converted':
      return 'Converted';
    default:
      return state;
  }
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request});

  final ContractRequest request;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _acting = false;

  Future<void> _runAction(String action) async {
    setState(() => _acting = true);
    try {
      await ref.read(contractRequestRepositoryProvider).performAction(widget.request.id, action);
      ref.invalidate(adminContractRequestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final (bg, fg) = _contractStatusColors(request.state);
    final terminal = request.state == 'converted';

    return Opacity(
      opacity: terminal ? 0.7 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.purpleChipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.business_outlined, size: 16, color: AppColors.purple),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.businessName,
                        style: AppText.bodySmallBold(AppColors.ink900).copyWith(fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.code} · ${request.contactPerson}',
                        style: AppText.caption(AppColors.muted500).copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
                  child: Text(_contractStateLabel(request.state), style: AppText.microBold(fg)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_capitalize(request.businessType)} · ${request.notes} · ${formatDate(request.date)}',
              style: AppText.caption(AppColors.muted500),
            ),
            if (!terminal && request.state != 'cancel') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (request.state == 'submitted') ...[
                    Expanded(
                      child: _ActionButton(
                        label: 'Start Negotiation',
                        loading: _acting,
                        onPressed: () => _runAction('negotiate'),
                      ),
                    ),
                  ],
                  if (request.state == 'in_negotiation') ...[
                    Expanded(
                      child: _ActionButton(
                        label: 'Convert to Contract',
                        loading: _acting,
                        onPressed: () => _runAction('convert'),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Cancel',
                    outlined: true,
                    loading: false,
                    onPressed: _acting ? null : () => _runAction('cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final bool loading;
  final bool outlined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
          )
        : Text(label, style: AppText.captionBold(outlined ? AppColors.redText : Colors.white));

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.redText, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: child,
    );
  }
}
