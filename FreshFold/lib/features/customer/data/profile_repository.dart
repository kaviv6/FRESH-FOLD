import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../models/user_profile.dart';

/// `POST /api/v1/profile` doubles as both the getter and setter — passing
/// any writable field updates it, then the full profile is returned.
class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<UserProfile> getProfile() async {
    final res = await _api.call('profile');
    return UserProfile.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<UserProfile> updateProfile({
    String? name,
    String? mobile,
    String? phone,
    String? street,
    String? street2,
    String? city,
    String? zip,
  }) async {
    final res = await _api.call('profile', {
      if (name != null) 'name': name,
      if (mobile != null) 'mobile': mobile,
      if (phone != null) 'phone': phone,
      if (street != null) 'street': street,
      if (street2 != null) 'street2': street2,
      if (city != null) 'city': city,
      if (zip != null) 'zip': zip,
    });
    return UserProfile.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

final profileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});
