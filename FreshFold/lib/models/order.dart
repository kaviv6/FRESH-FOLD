/// Mirrors `laundry.order.line` as returned by `_format_order`.
class OrderLine {
  const OrderLine({
    required this.id,
    required this.product,
    required this.serviceType,
    required this.quantity,
    required this.priceUnit,
    required this.subtotal,
    required this.description,
  });

  final int id;
  final String product;
  final String? serviceType;
  final int quantity;
  final double priceUnit;
  final double subtotal;
  final String description;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        id: json['id'] as int,
        product: json['product'] as String? ?? '',
        serviceType: json['service_type'] as String?,
        quantity: (json['quantity'] as num).toInt(),
        priceUnit: (json['price_unit'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
        description: json['description'] as String? ?? '',
      );
}

/// Mirrors `laundry.order` as returned by `_format_order` in
/// `controllers/api_controller.py`. States: draft, order, invoiced, cancel.
class LaundryOrder {
  const LaundryOrder({
    required this.id,
    required this.name,
    required this.customer,
    required this.orderDate,
    required this.state,
    required this.subtotal,
    required this.totalAmount,
    this.amountPaid = 0,
    required this.amountDue,
    this.paymentStatus = 'not_paid',
    required this.paymentMethod,
    this.promoCode,
    this.promoDiscount = 0,
    this.isExpress = false,
    this.eta,
    this.riderId,
    this.riderName,
    this.garmentCount = 0,
    this.note,
    this.lines,
  });

  final int id;
  final String name;
  final String customer;
  final DateTime? orderDate;
  final String state;
  final double subtotal;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final String paymentStatus;
  final String paymentMethod;
  final String? promoCode;
  final double promoDiscount;
  final bool isExpress;
  final DateTime? eta;
  final int? riderId;
  final String? riderName;
  final int garmentCount;
  final String? note;
  final List<OrderLine>? lines;

  factory LaundryOrder.fromJson(Map<String, dynamic> json) => LaundryOrder(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        customer: json['customer'] as String? ?? '',
        orderDate: json['order_date'] != null
            ? DateTime.tryParse(json['order_date'] as String)
            : null,
        state: json['state'] as String? ?? 'draft',
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
        amountDue: (json['amount_due'] as num?)?.toDouble() ??
            (json['total_amount'] as num?)?.toDouble() ??
            0,
        paymentStatus: json['payment_status'] as String? ?? 'not_paid',
        paymentMethod: json['payment_method'] as String? ?? 'cod',
        promoCode: json['promo_code'] as String?,
        promoDiscount: (json['promo_discount'] as num?)?.toDouble() ?? 0,
        isExpress: json['is_express'] as bool? ?? false,
        eta: json['eta'] != null ? DateTime.tryParse(json['eta'] as String) : null,
        riderId: json['rider_id'] as int?,
        riderName: json['rider_name'] as String?,
        garmentCount: (json['garment_count'] as num?)?.toInt() ?? 0,
        note: json['note'] as String?,
        lines: (json['lines'] as List?)
            ?.map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
