import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_pickups_screen.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/customer/presentation/address_book_screen.dart';
import '../features/customer/presentation/address_form_screen.dart';
import '../features/customer/presentation/book_pickup_items_screen.dart';
import '../features/customer/presentation/book_pickup_schedule_screen.dart';
import '../features/customer/presentation/booking_confirmed_screen.dart';
import '../features/customer/presentation/business_enquiry_screen.dart';
import '../features/customer/presentation/customer_shell.dart';
import '../models/address.dart';
import '../features/customer/presentation/order_detail_screen.dart';
import '../features/customer/presentation/pickup_detail_screen.dart';
import '../features/rider/presentation/garment_scan_screen.dart';
import '../features/rider/presentation/rider_pickup_detail_screen.dart';
import '../features/rider/presentation/rider_shell.dart';
import 'app_routes.dart';

/// The full route table. Role shells (`CustomerShell`/`RiderShell`/
/// `AdminShell`) each own their bottom-nav tabs internally via an
/// `IndexedStack` — see `AppRoutes` for why only shell roots and pushed
/// full-screen routes appear here. Detail routes take an `:id` path
/// segment, parsed as `int` and passed to the screen's required
/// `pickupId`/`orderId` constructor param.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (context, state) => const SignupScreen()),

      // Customer
      GoRoute(
        path: AppRoutes.customerRoot,
        builder: (context, state) => const CustomerShell(),
      ),
      GoRoute(
        path: AppRoutes.bookPickupItems,
        builder: (context, state) => const BookPickupItemsScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookPickupSchedule,
        builder: (context, state) => const BookPickupScheduleScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingConfirmed,
        builder: (context, state) => BookingConfirmedScreen(extra: state.extra),
      ),
      GoRoute(
        path: AppRoutes.businessEnquiry,
        builder: (context, state) => const BusinessEnquiryScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressBook,
        builder: (context, state) => const AddressBookScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressForm,
        builder: (context, state) => AddressFormScreen(existing: state.extra as Address?),
      ),
      GoRoute(
        path: '/customer/pickups/:id',
        builder: (context, state) => PickupDetailScreen(
          pickupId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/customer/orders/:id',
        builder: (context, state) => OrderDetailScreen(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Rider
      GoRoute(
        path: AppRoutes.riderRoot,
        builder: (context, state) => const RiderShell(),
      ),
      GoRoute(
        path: '/rider/pickups/:id',
        builder: (context, state) => RiderPickupDetailScreen(
          pickupId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.riderScan,
        builder: (context, state) => const GarmentScanScreen(),
      ),

      // Admin
      GoRoute(
        path: AppRoutes.adminRoot,
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: AppRoutes.adminPickups,
        builder: (context, state) => const AdminPickupsScreen(),
      ),
    ],
  );
});
