import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/service_type.dart';

/// One selected line in the in-progress pickup booking.
class CartLine {
  const CartLine({required this.service, required this.qty});
  final ServiceType service;
  final int qty;

  double get subtotal => service.price * qty;
}

/// Shared state for the multi-step "book a pickup" flow. Both the
/// Services & Pricing tab and Book Pickup step 1 read/write this same
/// cart, so quantities picked from either screen stay in sync — matching
/// the design, where Book Pickup step 1 opens already showing whatever was
/// picked on the Services screen.
class BookingCartState {
  const BookingCartState({
    this.lines = const {},
    this.scheduleDate,
    this.timeSlotLabel = '11–1 PM',
    this.paymentMethod = 'cod',
  });

  final Map<int, CartLine> lines; // keyed by service_type_id
  final DateTime? scheduleDate;
  final String timeSlotLabel;
  final String paymentMethod;

  int get itemCount => lines.values.fold(0, (sum, l) => sum + l.qty);
  double get total => lines.values.fold(0.0, (sum, l) => sum + l.subtotal);
  bool get isEmpty => lines.isEmpty;

  /// Lines shaped for `POST /api/v1/pickup/create`.
  List<Map<String, dynamic>> toApiLines() {
    return lines.values
        .map((l) => {'service_type_id': l.service.id, 'qty': l.qty})
        .toList();
  }

  BookingCartState copyWith({
    Map<int, CartLine>? lines,
    DateTime? scheduleDate,
    String? timeSlotLabel,
    String? paymentMethod,
  }) {
    return BookingCartState(
      lines: lines ?? this.lines,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      timeSlotLabel: timeSlotLabel ?? this.timeSlotLabel,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class BookingCartController extends StateNotifier<BookingCartState> {
  BookingCartController() : super(const BookingCartState());

  void increment(ServiceType service) {
    final current = state.lines[service.id]?.qty ?? 0;
    final next = Map<int, CartLine>.from(state.lines);
    next[service.id] = CartLine(service: service, qty: current + 1);
    state = state.copyWith(lines: next);
  }

  void decrement(ServiceType service) {
    final current = state.lines[service.id]?.qty ?? 0;
    if (current <= 0) return;
    final next = Map<int, CartLine>.from(state.lines);
    if (current == 1) {
      next.remove(service.id);
    } else {
      next[service.id] = CartLine(service: service, qty: current - 1);
    }
    state = state.copyWith(lines: next);
  }

  void setSchedule(DateTime date, String timeSlotLabel) {
    state = state.copyWith(scheduleDate: date, timeSlotLabel: timeSlotLabel);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void reset() {
    state = const BookingCartState();
  }
}

final bookingCartProvider =
    StateNotifierProvider<BookingCartController, BookingCartState>((ref) {
  return BookingCartController();
});
