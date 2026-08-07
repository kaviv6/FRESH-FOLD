import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/address.dart';

/// Wraps `/api/v1/address/*` — the customer's saved address book. The first
/// address ever saved becomes the customer's own partner record server-side;
/// every one after that is a delivery child contact. See api_controller.py's
/// ADDRESS BOOK section for the full rationale.
class AddressRepository {
  AddressRepository(this._api);
  final ApiClient _api;

  Future<List<Address>> getAddresses() async {
    final res = await _api.call('address/list');
    final list = (res['data'] as List? ?? []);
    return list
        .map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Address> createAddress({
    required String street,
    String? street2,
    String? city,
    String? zip,
    String? state,
    String? country,
    String? label,
    bool setDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.call('address/create', {
      'street': street,
      if (street2 != null && street2.isNotEmpty) 'street2': street2,
      if (city != null && city.isNotEmpty) 'city': city,
      if (zip != null && zip.isNotEmpty) 'zip': zip,
      if (state != null && state.isNotEmpty) 'state': state,
      if (country != null && country.isNotEmpty) 'country': country,
      if (label != null && label.isNotEmpty) 'label': label,
      if (setDefault) 'set_default': true,
      if (latitude != null && longitude != null) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
    });
    return Address.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<Address> updateAddress({
    required int addressId,
    String? street,
    String? street2,
    String? city,
    String? zip,
    String? state,
    String? country,
    String? label,
    bool setDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.call('address/update', {
      'address_id': addressId,
      if (street != null && street.isNotEmpty) 'street': street,
      if (street2 != null) 'street2': street2,
      if (city != null && city.isNotEmpty) 'city': city,
      if (zip != null && zip.isNotEmpty) 'zip': zip,
      if (state != null && state.isNotEmpty) 'state': state,
      if (country != null && country.isNotEmpty) 'country': country,
      if (label != null) 'label': label,
      if (setDefault) 'set_default': true,
      if (latitude != null && longitude != null) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
    });
    return Address.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// Reverse-geocodes a device/map coordinate into address fields —
  /// powers "Use current location" and the map picker's "Confirm
  /// location" step. Returns the same lat/lng echoed back, ready to pass
  /// straight through to [createAddress]/[updateAddress].
  Future<ReverseGeocodeResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final res = await _api.call('geocode/reverse', {
      'latitude': latitude,
      'longitude': longitude,
    });
    return ReverseGeocodeResult.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// The primary address (a customer's own partner record) can't be
  /// deleted — the server rejects that call with a clear error.
  Future<void> deleteAddress(int addressId) async {
    await _api.call('address/delete', {'address_id': addressId});
  }

  Future<void> setDefaultAddress(int addressId) async {
    await _api.call('address/set_default', {'address_id': addressId});
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(apiClientProvider));
});

final addressesListProvider = FutureProvider.autoDispose<List<Address>>((ref) {
  return ref.watch(addressRepositoryProvider).getAddresses();
});
