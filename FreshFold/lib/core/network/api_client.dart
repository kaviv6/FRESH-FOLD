import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/auth_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around the Odoo `type='jsonrpc'` controller endpoints in
/// `laundry_management/controllers/api_controller.py`.
///
/// Odoo's `jsonrpc` route type expects a JSON-RPC 2.0 envelope
/// (`{"jsonrpc": "2.0", "method": "call", "params": {...}}`) and replies
/// with the handler's return value wrapped in `{"result": ...}`. This
/// client hides that envelope so callers just pass/receive the plain
/// `kwargs` dict the controller methods use.
class ApiClient {
  ApiClient({AuthStorage? authStorage})
      : _authStorage = authStorage ?? AuthStorage(),
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
          ),
        );

  final Dio _dio;
  final AuthStorage _authStorage;
  final _rng = Random();

  /// Posts to `/api/v1/<path>` and returns the decoded `result` payload.
  ///
  /// Throws [ApiException] when the transport fails or the controller
  /// returns `{"status": false, "message": "..."}`.
  Future<Map<String, dynamic>> call(
    String path, [
    Map<String, dynamic> params = const {},
  ]) async {
    final token = await _authStorage.readToken();
    try {
      final response = await _dio.post(
        '/api/v1/$path',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': params,
          'id': _rng.nextInt(1 << 31),
        },
      );

      final body = response.data;
      if (body is! Map) {
        throw ApiException('Unexpected response from server.');
      }
      if (body['error'] != null) {
        final err = body['error'];
        final message = err is Map
            ? (err['data']?['message'] ?? err['message'] ?? 'Request failed')
            : 'Request failed';
        throw ApiException(message.toString());
      }
      final result = body['result'];
      if (result is! Map) {
        throw ApiException('Unexpected response from server.');
      }
      final data = Map<String, dynamic>.from(result);
      if (data['status'] == false) {
        throw ApiException((data['message'] ?? 'Request failed').toString());
      }
      return data;
    } on DioException catch (e) {
      if (e.response != null) {
        final body = e.response!.data;
        if (body is Map && body['message'] != null) {
          throw ApiException(body['message'].toString());
        }
        throw ApiException('Server error (${e.response!.statusCode}).');
      }
      throw ApiException(_transportErrorMessage(e));
    }
  }

  /// GETs `/api/v1/<path>` and returns the raw response body — for binary
  /// endpoints (e.g. the invoice PDF) that aren't wrapped in the jsonrpc
  /// envelope [call] expects.
  Future<List<int>> downloadBytes(String path) async {
    final token = await _authStorage.readToken();
    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/$path',
        options: Options(
          responseType: ResponseType.bytes,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      if (e.response != null) {
        final body = e.response!.data;
        // Error responses from this route are small JSON bodies (see
        // _json_error in download_invoice_pdf) even though success
        // responses are raw PDF bytes — try to surface that message.
        if (body is List<int>) {
          try {
            final decoded = jsonDecode(utf8.decode(body));
            if (decoded is Map && decoded['message'] != null) {
              throw ApiException(decoded['message'].toString());
            }
          } on FormatException {
            // not JSON — fall through to the generic message below
          }
        }
        throw ApiException('Server error (${e.response!.statusCode}).');
      }
      throw ApiException(_transportErrorMessage(e));
    }
  }

  String _transportErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection and the API_BASE_URL setting.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
