/// Runtime configuration for the app.
///
/// Point this at your Odoo instance:
///   flutter run --dart-define=API_BASE_URL=https://your-odoo-host.example.com
///
/// Defaults to the Android emulator's loopback alias so a locally-run Odoo
/// dev server is reachable out of the box on Android; override for iOS
/// simulator (http://localhost:8069) or a real device/server.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://unilobed-acrophonically-kian.ngrok-free.dev',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
