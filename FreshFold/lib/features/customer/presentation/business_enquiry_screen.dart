import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_field_decoration.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../shared/data/contract_request_repository.dart';

const _businessTypes = ['Hotel', 'Restaurant', 'Hostel'];

/// Screen 13 · Business Enquiry (B2B). Submits to
/// `/api/v1/contract-request/create`, landing as a real
/// `laundry.contract.request` in Odoo (Laundry Management > Contracts >
/// Requests) for an admin to pick up from there.
class BusinessEnquiryScreen extends ConsumerStatefulWidget {
  const BusinessEnquiryScreen({super.key});

  @override
  ConsumerState<BusinessEnquiryScreen> createState() => _BusinessEnquiryScreenState();
}

class _BusinessEnquiryScreenState extends ConsumerState<BusinessEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedType = _businessTypes.first;
  bool _submitting = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(contractRequestRepositoryProvider).submit(
            businessName: _businessNameCtrl.text.trim(),
            contactPerson: _contactPersonCtrl.text.trim(),
            businessType: _selectedType,
            phone: _phoneCtrl.text.trim(),
            notes: _notesCtrl.text.trim(),
          );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.teal),
              const SizedBox(width: 10),
              const Text('Enquiry received'),
            ],
          ),
          content: const Text("We'll get back to you shortly with volume pricing details."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not submit your enquiry.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const DetailAppBar(title: 'Business Enquiry', trailing: LogoutButton()),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For hotels, restaurants & hostels — get volume pricing and a dedicated account manager.',
                style: AppText.caption(AppColors.muted450).copyWith(fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 18),
              _FieldLabel('Business type'),
              Row(
                children: [
                  for (var i = 0; i < _businessTypes.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _TypePill(
                        label: _businessTypes[i],
                        selected: _businessTypes[i] == _selectedType,
                        onTap: () => setState(() => _selectedType = _businessTypes[i]),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _FieldLabel('Business name'),
              TextFormField(
                controller: _businessNameCtrl,
                decoration: appFieldDecoration(hint: 'The Grand Palace Hotel'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _FieldLabel('Contact person'),
              TextFormField(
                controller: _contactPersonCtrl,
                decoration: appFieldDecoration(hint: 'Suresh Patil'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _FieldLabel('Phone'),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: appFieldDecoration(hint: '+91 98xxxxxx21'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _FieldLabel('Expected volume / notes'),
              TextFormField(
                controller: _notesCtrl,
                minLines: 3,
                maxLines: 4,
                decoration: appFieldDecoration(hint: '~40 kg linen daily, need morning collection before 9 AM.'),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Submit Enquiry',
                color: AppColors.purple,
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppText.caption(AppColors.ink500).copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.transparent,
          border: selected ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: selected
              ? AppText.caption(Colors.white).copyWith(fontWeight: FontWeight.w700)
              : AppText.caption(AppColors.ink700).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
