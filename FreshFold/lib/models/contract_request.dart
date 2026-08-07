/// Mirrors `laundry.contract.request` as returned by
/// `_format_contract_request` in `controllers/api_controller.py`.
/// States: submitted, in_negotiation, converted, cancel.
class ContractRequest {
  const ContractRequest({
    required this.id,
    required this.code,
    required this.businessName,
    required this.contactPerson,
    required this.businessType,
    required this.notes,
    required this.state,
    required this.date,
  });

  final int id;
  final String code;
  final String businessName;
  final String contactPerson;
  final String businessType;
  final String notes;
  final String state;
  final DateTime date;

  factory ContractRequest.fromJson(Map<String, dynamic> json) => ContractRequest(
        id: json['id'] as int,
        code: json['name'] as String? ?? '',
        businessName: json['business_name'] as String? ?? '',
        contactPerson: json['contact_name'] as String? ?? '',
        businessType: json['business_type'] as String? ?? 'other',
        // The server stores this as an HTML field (rich-text notes); strip
        // tags for the plain-text card display the app uses.
        notes: (json['notes'] as String? ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim(),
        state: json['state'] as String? ?? 'submitted',
        date: json['date'] != null ? DateTime.tryParse(json['date'] as String) ?? DateTime.now() : DateTime.now(),
      );
}
