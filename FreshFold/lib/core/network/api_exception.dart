/// Raised for any failed API call — either a transport failure or a
/// `{"status": false, "message": ...}` response body from the Odoo
/// controller (see `laundry_management/controllers/api_controller.py`).
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
