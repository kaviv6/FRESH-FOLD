/// Mirrors the `address` block in `_format_pickup`.
class PickupAddress {
  const PickupAddress({
    required this.street,
    required this.street2,
    required this.city,
    required this.zip,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
  });

  final String street;
  final String street2;
  final String city;
  final String zip;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;

  factory PickupAddress.fromJson(Map<String, dynamic> json) => PickupAddress(
        street: json['street'] as String? ?? '',
        street2: json['street2'] as String? ?? '',
        city: json['city'] as String? ?? '',
        zip: json['zip'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  /// Single-line address string for display, e.g. in the pickup card.
  String get singleLine {
    final parts = [street, street2, city, zip]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Google Maps directions URL — coordinates when we have them (more
  /// accurate), falling back to the formatted address string otherwise.
  /// Mirrors the same fallback logic as the Odoo backend's own
  /// `action_open_map()` (used by the web/backend UI).
  String get googleMapsUrl {
    final destination = (latitude != null && longitude != null)
        ? '$latitude,$longitude'
        : Uri.encodeComponent(singleLine.isNotEmpty ? singleLine : city);
    return 'https://www.google.com/maps/dir/?api=1&travelmode=driving&destination=$destination';
  }
}

/// Mirrors `laundry.pickup.request.line` as returned by `_format_pickup`.
class PickupLine {
  const PickupLine({
    required this.id,
    required this.product,
    required this.serviceType,
    required this.quantity,
    required this.priceUnit,
    required this.subtotal,
  });

  final int id;
  final String product;
  final String? serviceType;
  final int quantity;
  final double priceUnit;
  final double subtotal;

  factory PickupLine.fromJson(Map<String, dynamic> json) => PickupLine(
        id: json['id'] as int,
        product: json['product'] as String? ?? '',
        serviceType: json['service_type'] as String?,
        quantity: (json['quantity'] as num).toInt(),
        priceUnit: (json['price_unit'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

/// Mirrors `laundry.pickup.request` as returned by `_format_pickup`.
/// States: draft, scheduled, picked, delivered, cancel.
class PickupRequest {
  const PickupRequest({
    required this.id,
    required this.name,
    required this.customer,
    required this.scheduleDate,
    required this.pickupDate,
    required this.state,
    required this.totalAmount,
    required this.paymentMethod,
    required this.orderId,
    required this.address,
    this.riderId,
    this.riderName,
    this.lines,
    this.amountDue = 0,
    this.paymentStatus = 'not_paid',
  });

  final int id;
  final String name;
  final String customer;
  final DateTime? scheduleDate;
  final DateTime? pickupDate;
  final String state;
  final double totalAmount;
  final String paymentMethod;
  final int? orderId;
  final PickupAddress address;
  final int? riderId;
  final String? riderName;
  final List<PickupLine>? lines;
  final double amountDue;
  final String paymentStatus;

  factory PickupRequest.fromJson(Map<String, dynamic> json) => PickupRequest(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        customer: json['customer'] as String? ?? '',
        scheduleDate: json['schedule_date'] != null
            ? DateTime.tryParse(json['schedule_date'] as String)
            : null,
        pickupDate: json['pickup_date'] != null
            ? DateTime.tryParse(json['pickup_date'] as String)
            : null,
        state: json['state'] as String? ?? 'draft',
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['payment_method'] as String? ?? 'cod',
        orderId: json['order_id'] as int?,
        address: PickupAddress.fromJson(
          Map<String, dynamic>.from(json['address'] as Map? ?? {}),
        ),
        riderId: json['rider_id'] as int?,
        riderName: json['rider_name'] as String?,
        lines: (json['lines'] as List?)
            ?.map((e) => PickupLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        amountDue: (json['amount_due'] as num?)?.toDouble() ??
            (json['total_amount'] as num?)?.toDouble() ??
            0,
        paymentStatus: json['payment_status'] as String? ?? 'not_paid',
      );
}
