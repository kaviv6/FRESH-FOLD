/// Centralized route path strings so screens never hardcode a string that
/// could drift from `app_router.dart`.
///
/// Each role's bottom-nav tabs are *not* separate go_router routes — they
/// are handled as an internal `IndexedStack` inside that role's shell
/// widget (`CustomerShell`, `RiderShell`, `AdminShell`), matching how a
/// typical bottom-nav app behaves without needing StatefulShellRoute
/// branches. Only the shell root and pushed full-screen routes (detail
/// pages, multi-step flows) are real routes.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';

  // Role shell roots (each renders its own bottom nav + tabs internally).
  static const customerRoot = '/customer';
  static const riderRoot = '/rider';
  static const adminRoot = '/admin';

  // Customer — pushed full-screen routes
  static const bookPickupItems = '/customer/book-pickup/items';
  static const bookPickupSchedule = '/customer/book-pickup/schedule';
  static const bookingConfirmed = '/customer/book-pickup/confirmed';
  static const businessEnquiry = '/customer/business-enquiry';
  static const addressBook = '/customer/addresses';
  static const addressForm = '/customer/addresses/form';
  static String pickupDetail(int id) => '/customer/pickups/$id';
  static String orderDetail(int id) => '/customer/orders/$id';

  // Rider — pushed full-screen routes
  static String riderPickupDetail(int id) => '/rider/pickups/$id';
  static const riderScan = '/rider/scan';

  // Admin — pushed full-screen routes
  static const adminPickups = '/admin/pickups';
}
