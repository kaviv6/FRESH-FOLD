import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/shared/data/push_repository.dart';

/// Runs in a separate isolate when a push arrives while the app is
/// terminated/backgrounded. FCM already renders the system notification for
/// a `notification`-payload push automatically, so this is a required
/// registration hook rather than a place that needs to do work itself.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Requests notification permission, fetches the device's FCM token, and
/// registers it with the backend (`POST /api/v1/push/register`, consumed by
/// `laundry.push.service` server-side — see ROADMAP.md E1). Call once after
/// a session is established (login, signup, or a restored session).
///
/// Swallows all errors: Firebase may not be configured yet for this build
/// (no `google-services.json` / `GoogleService-Info.plist`), the user may
/// deny the permission prompt, or the device may be offline — none of those
/// should block auth or crash the app, push notifications just stay off.
Future<void> registerPushToken(Ref ref) async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token == null) return;

    await ref.read(pushRepositoryProvider).registerToken(token);

    messaging.onTokenRefresh.listen((refreshed) {
      ref.read(pushRepositoryProvider).registerToken(refreshed).catchError((_) {});
    });
  } catch (e) {
    debugPrint('Push notification setup skipped: $e');
  }
}
