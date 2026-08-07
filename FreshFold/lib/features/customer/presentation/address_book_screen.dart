import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/address.dart';
import '../../../routing/app_routes.dart';
import '../data/address_repository.dart';

/// Address book — list, add, edit, delete, and set-default for saved
/// addresses. Wraps `/api/v1/address/*`, which had no UI before this.
class AddressBookScreen extends ConsumerWidget {
  const AddressBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: const DetailAppBar(title: 'My Addresses', trailing: LogoutButton()),
      body: AsyncValueView<List<Address>>(
        value: addressesAsync,
        onRetry: () => ref.invalidate(addressesListProvider),
        data: (context, addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_outlined, size: 32, color: AppColors.muted300),
                    const SizedBox(height: 12),
                    Text(
                      'No saved addresses yet.',
                      textAlign: TextAlign.center,
                      style: AppText.body(AppColors.muted450),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AddressCard(address: addresses[i]),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: PrimaryButton(
            label: 'Add New Address',
            icon: Icons.add,
            onPressed: () async {
              final saved = await context.push<bool>(AppRoutes.addressForm);
              if (saved == true) ref.invalidate(addressesListProvider);
            },
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends ConsumerStatefulWidget {
  const _AddressCard({required this.address});
  final Address address;

  @override
  ConsumerState<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends ConsumerState<_AddressCard> {
  bool _busy = false;

  Future<void> _setDefault() async {
    setState(() => _busy = true);
    try {
      await ref.read(addressRepositoryProvider).setDefaultAddress(widget.address.id);
      ref.invalidate(addressesListProvider);
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.toString() : 'Could not set default address.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this address?'),
        content: Text('"${widget.address.label}" will be removed from your address book.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.redText)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(addressRepositoryProvider).deleteAddress(widget.address.id);
      ref.invalidate(addressesListProvider);
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.toString() : 'Could not delete address.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.address;
    return Opacity(
      opacity: _busy ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: address.isDefault ? AppColors.teal : AppColors.borderLight, width: address.isDefault ? 1.5 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  address.isPrimary ? Icons.home_outlined : Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address.label, style: AppText.bodyBold(AppColors.ink900)),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.tealChipBg, borderRadius: BorderRadius.circular(100)),
                    child: Text('DEFAULT', style: AppText.microBold(AppColors.tealTextStrong)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.singleLine.isEmpty ? 'No address details' : address.singleLine,
              style: AppText.body(AppColors.ink600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!address.isDefault)
                  TextButton(
                    onPressed: _busy ? null : _setDefault,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                    child: Text('Set as default', style: AppText.bodySmallBold(AppColors.tealText).copyWith(fontSize: 12.5)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final saved = await context.push<bool>(AppRoutes.addressForm, extra: address);
                          if (saved == true) ref.invalidate(addressesListProvider);
                        },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                  child: Text('Edit', style: AppText.bodySmallBold(AppColors.ink600).copyWith(fontSize: 12.5)),
                ),
                if (!address.isPrimary) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                    child: Text('Delete', style: AppText.bodySmallBold(AppColors.redText).copyWith(fontSize: 12.5)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
