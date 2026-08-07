import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_field_decoration.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/address.dart';
import '../data/address_repository.dart';
import 'location_picker_screen.dart';

/// Add or edit a saved address. Pass an [existing] address to edit it,
/// or omit it to create a new one. Pops `true` on success so the caller
/// (AddressBookScreen) knows to refresh its list.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});
  final Address? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _labelCtrl = TextEditingController(text: widget.existing?.label ?? '');
  late final _streetCtrl = TextEditingController(text: widget.existing?.street ?? '');
  late final _street2Ctrl = TextEditingController(text: widget.existing?.street2 ?? '');
  late final _cityCtrl = TextEditingController(text: widget.existing?.city ?? '');
  late final _zipCtrl = TextEditingController(text: widget.existing?.zip ?? '');
  late final _stateCtrl = TextEditingController(text: widget.existing?.state ?? '');
  late final _countryCtrl = TextEditingController(text: widget.existing?.country ?? '');
  late bool _setDefault = widget.existing?.isDefault ?? false;
  late double? _latitude = widget.existing?.latitude;
  late double? _longitude = widget.existing?.longitude;
  bool _submitting = false;
  bool _locating = false;

  bool get _isEdit => widget.existing != null;
  bool get _hasCoordinates => _latitude != null && _longitude != null;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _streetCtrl.dispose();
    _street2Ctrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _applyReverseGeocode(ReverseGeocodeResult result) {
    setState(() {
      if (result.street.isNotEmpty) _streetCtrl.text = result.street;
      if (result.street2.isNotEmpty) _street2Ctrl.text = result.street2;
      if (result.city.isNotEmpty) _cityCtrl.text = result.city;
      if (result.zip.isNotEmpty) _zipCtrl.text = result.zip;
      if (result.state.isNotEmpty) _stateCtrl.text = result.state;
      if (result.country.isNotEmpty) _countryCtrl.text = result.country;
      _latitude = result.latitude;
      _longitude = result.longitude;
    });
  }

  Future<void> _reverseGeocodeAndApply(double latitude, double longitude) async {
    try {
      final result = await ref.read(addressRepositoryProvider).reverseGeocode(
            latitude: latitude,
            longitude: longitude,
          );
      _applyReverseGeocode(result);
    } catch (e) {
      // Reverse-geocoding failing shouldn't block the flow — the exact
      // coordinate is still more useful to keep than to discard, the
      // customer just has to fill in street/city themselves.
      setState(() {
        _latitude = latitude;
        _longitude = longitude;
      });
      if (!mounted) return;
      final message = e is ApiException
          ? e.toString()
          : 'Got your location, but could not fill in the address automatically — please check the fields below.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await determinePosition();
      await _reverseGeocodeAndApply(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      final message = e is LocationException ? e.toString() : 'Could not get your location.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _adjustOnMap() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _hasCoordinates ? LatLng(_latitude!, _longitude!) : null,
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _locating = true);
    await _reverseGeocodeAndApply(picked.latitude, picked.longitude);
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(addressRepositoryProvider);
      if (_isEdit) {
        await repo.updateAddress(
          addressId: widget.existing!.id,
          street: _streetCtrl.text.trim(),
          street2: _street2Ctrl.text.trim(),
          city: _cityCtrl.text.trim(),
          zip: _zipCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          country: _countryCtrl.text.trim(),
          label: _labelCtrl.text.trim(),
          setDefault: _setDefault,
          latitude: _latitude,
          longitude: _longitude,
        );
      } else {
        await repo.createAddress(
          street: _streetCtrl.text.trim(),
          street2: _street2Ctrl.text.trim(),
          city: _cityCtrl.text.trim(),
          zip: _zipCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          country: _countryCtrl.text.trim(),
          label: _labelCtrl.text.trim(),
          setDefault: _setDefault,
          latitude: _latitude,
          longitude: _longitude,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.toString() : 'Could not save address.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DetailAppBar(title: _isEdit ? 'Edit Address' : 'Add Address'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _useCurrentLocation,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.teal, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _locating
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                              )
                            : const Icon(Icons.my_location, size: 17, color: AppColors.teal),
                        label: Text('Use Current Location', style: AppText.bodySmallBold(AppColors.teal).copyWith(fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _adjustOnMap,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 17, color: AppColors.ink600),
                        label: Text('Adjust on Map', style: AppText.bodySmallBold(AppColors.ink600).copyWith(fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
                if (_hasCoordinates) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Text('Exact location saved', style: AppText.caption(AppColors.tealText)),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _Field('Label', _labelCtrl, hint: 'Home, Office, ...'),
                _Field('Street address', _streetCtrl, hint: '123 Main St', required: true),
                _Field('Apartment / Area (optional)', _street2Ctrl, hint: 'Flat 4B'),
                Row(
                  children: [
                    Expanded(child: _Field('City', _cityCtrl, hint: 'Rajkot')),
                    const SizedBox(width: 12),
                    Expanded(child: _Field('PIN code', _zipCtrl, hint: '360001', keyboardType: TextInputType.number)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _Field('State', _stateCtrl, hint: 'Gujarat')),
                    const SizedBox(width: 12),
                    Expanded(child: _Field('Country', _countryCtrl, hint: 'India')),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _setDefault,
                  onChanged: (v) => setState(() => _setDefault = v),
                  activeThumbColor: AppColors.teal,
                  title: Text('Set as default address', style: AppText.bodySmallBold(AppColors.ink900)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _isEdit ? 'Save Changes' : 'Save Address',
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.controller, {required this.hint, this.required = false, this.keyboardType});
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.captionBold(AppColors.ink500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: appFieldDecoration(hint: hint),
            validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
          ),
        ],
      ),
    );
  }
}
