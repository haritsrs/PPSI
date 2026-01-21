import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class XenditService {
  static const String baseUrl = 'https://api.xendit.co';
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  // Private keys - should not be exposed
  String? get _secretKey => dotenv.env['XENDIT_SECRET_KEY'];

  // Get authorization header
  Map<String, String> get _headers {
    if (_secretKey == null || _secretKey!.isEmpty) {
      throw Exception('Xendit secret key is not set. Please add XENDIT_SECRET_KEY to .env file');
    }
    final authString = base64Encode(utf8.encode('$_secretKey:'));
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $authString',
    };
  }

  // Create QRIS payment
  Future<Map<String, dynamic>> createQRIS({
    required double amount,
    required String referenceId,
    required String callbackUrl,
    String? expiredAt,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/qr_codes');
      
      final body = {
  'external_id': referenceId,
  'type': 'DYNAMIC',
  'channel_code': 'ID_QRIS',
  'currency': 'IDR',
  'amount': amount,
  'callback_url': callbackUrl,
  if (expiredAt != null) 'expires_at': expiredAt,
};

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Don't expose full response body which may contain sensitive information
        // Only log status code for debugging
        throw Exception('Gagal membuat QRIS. Silakan coba lagi.');
      }
    } on TimeoutException {
      throw Exception('Permintaan ke Xendit melebihi batas waktu. Silakan coba lagi.');
    } catch (e) {
      // Don't expose internal error details
      throw Exception('Gagal membuat QRIS. Silakan coba lagi.');
    }
  }

  // Get QRIS status
  Future<Map<String, dynamic>> getQRISStatus(String qrId) async {
    try {
      final url = Uri.parse('$baseUrl/qr_codes/$qrId');

      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Don't expose full response body which may contain sensitive information
        throw Exception('Gagal memeriksa status QRIS. Silakan coba lagi.');
      }
    } on TimeoutException {
      throw Exception('Permintaan ke Xendit melebihi batas waktu. Silakan coba lagi.');
    } catch (e) {
      // Don't expose internal error details
      throw Exception('Gagal memeriksa status QRIS. Silakan coba lagi.');
    }
  }

  // Create Virtual Account
  Future<Map<String, dynamic>> createVirtualAccount({
    required String externalId,
    required String bankCode,
    required String name,
    required double amount,
    DateTime? expiredAt,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/virtual_accounts');

      final body = {
        'external_id': externalId,
        'bank_code': bankCode,
        'name': name,
        'expected_amount': amount,
        'is_closed': true,
        'is_single_use': true,
        if (expiredAt != null) 'expiration_date': expiredAt.toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Don't expose full response body which may contain sensitive information
        throw Exception('Gagal membuat Virtual Account. Silakan coba lagi.');
      }
    } on TimeoutException {
      throw Exception('Permintaan ke Xendit melebihi batas waktu. Silakan coba lagi.');
    } catch (e) {
      // Don't expose internal error details
      throw Exception('Gagal membuat Virtual Account. Silakan coba lagi.');
    }
  }

  // Get Virtual Account status
  Future<Map<String, dynamic>> getVirtualAccountStatus(String vaId) async {
    try {
      final url = Uri.parse('$baseUrl/virtual_accounts/$vaId');

      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Don't expose full response body which may contain sensitive information
        throw Exception('Gagal memeriksa status Virtual Account. Silakan coba lagi.');
      }
    } on TimeoutException {
      throw Exception('Permintaan ke Xendit melebihi batas waktu. Silakan coba lagi.');
    } catch (e) {
      // Don't expose internal error details
      throw Exception('Gagal memeriksa status Virtual Account. Silakan coba lagi.');
    }
  }

  // List available banks for Virtual Account
  List<Map<String, String>> getAvailableBanks() {
    return [
      {'code': 'BCA', 'name': 'Bank Central Asia (BCA)'},
      {'code': 'BNI', 'name': 'Bank Negara Indonesia (BNI)'},
      {'code': 'BRI', 'name': 'Bank Rakyat Indonesia (BRI)'},
      {'code': 'MANDIRI', 'name': 'Bank Mandiri'},
      {'code': 'PERMATA', 'name': 'Bank Permata'},
    ];
  }
}


