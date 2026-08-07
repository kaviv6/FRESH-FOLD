import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

/// Wraps `POST /api/v1/push/register` — stores the device's FCM token on
/// `res.users.push_token` so the backend's `laundry.push.service` can
/// deliver order/pickup state-change notifications (ROADMAP.md E1).
class PushRepository {
  PushRepository(this._api);
  final ApiClient _api;

  Future<void> registerToken(String fcmToken) async {
    await _api.call('push/register', {'fcm_token': fcmToken});
  }
}

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  return PushRepository(ref.watch(apiClientProvider));
});
