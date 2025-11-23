import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_exception.dart';

final RegExp _multiWhitespace = RegExp(r'\s+');
// Enhanced dangerous characters: control chars, script injection patterns, SQL-like patterns, path traversal
final RegExp _dangerousChars = RegExp(
  r'[\u0000-\u001F\u007F-\u009F' // Control characters
  r'<>$`;{}' // Script injection characters
  r'\\\/' // Path traversal
  r'\[\]\(\)' // Function call patterns
  r'&#' // HTML entity starts
  r'"]' // Quote patterns that could break contexts
);
// Additional patterns for common XSS vectors
final RegExp _xssPatterns = RegExp(
  r'(?i)(javascript|onerror|onload|onclick|onmouseover|onfocus|onblur|eval|expression|vbscript|data:text/html)',
  caseSensitive: false,
);
final RegExp _numberSanitizer = RegExp(r'[^0-9.,-]');

/// Common security helpers for sanitisation, rate limiting, and encryption.
class SecurityUtils {
  const SecurityUtils._();

  static String sanitizeInput(String value) {
    if (value.isEmpty) return value;
    
    // Remove dangerous characters
    var cleaned = value.replaceAll(_dangerousChars, '');
    
    // Remove XSS patterns (case-insensitive)
    cleaned = cleaned.replaceAll(_xssPatterns, '');
    
    // Normalize whitespace
    final normalisedWhitespace = cleaned.replaceAll(_multiWhitespace, ' ').trim();
    
    return normalisedWhitespace;
  }

  static String sanitizeNumber(String value) {
    if (value.isEmpty) return value;
    return value.replaceAll(_numberSanitizer, '').trim();
  }

  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        result[key] = sanitizeInput(value);
      } else if (value is Map<String, dynamic>) {
        result[key] = sanitizeMap(value);
      } else if (value is List) {
        result[key] = value
            .map((item) => item is Map<String, dynamic>
                ? sanitizeMap(item)
                : item is String
                    ? sanitizeInput(item)
                    : item)
            .toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static String abbreviate(String value, {int maxLength = 120}) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}…';
  }
}

class RateLimiter {
  RateLimiter._();

  static final Map<String, DateTime> _lastCallByKey = {};

  static bool allow(String key, {Duration interval = const Duration(milliseconds: 800)}) {
    final now = DateTime.now();
    final lastCall = _lastCallByKey[key];
    if (lastCall != null && now.difference(lastCall) < interval) {
      return false;
    }
    _lastCallByKey[key] = now;
    return true;
  }
}

class EncryptionHelper {
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal() {
    final rawKey = dotenv.env['ENCRYPTION_KEY'];
    if (rawKey == null || rawKey.isEmpty) {
      throw Exception(
        'ENCRYPTION_KEY must be set in environment variables. '
        'Please add ENCRYPTION_KEY to your .env file. '
        'This is required for secure data encryption.'
      );
    }
    final keyBytes = sha256.convert(utf8.encode(rawKey)).bytes;
    final keySlice = keyBytes.sublist(0, 32); // AES-256 key
    _key = enc.Key(Uint8List.fromList(keySlice));
    _iv = enc.IV.fromLength(16);
    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
  }

  static final EncryptionHelper _instance = EncryptionHelper._internal();

  late final enc.Key _key;
  late final enc.IV _iv;
  late final enc.Encrypter _encrypter;

  String encrypt(String plaintext) {
    if (plaintext.isEmpty) {
      throw const ValidationException('Data sensitif tidak boleh kosong saat dienkripsi.');
    }
    try {
      final sanitized = SecurityUtils.sanitizeInput(plaintext);
      return _encrypter.encrypt(sanitized, iv: _iv).base64;
    } catch (error, stackTrace) {
      debugPrint('Encryption error: $error\n$stackTrace');
      rethrow;
    }
  }

  String? decryptIfPossible(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return null;
    try {
      return _encrypter.decrypt64(cipherText, iv: _iv);
    } catch (error) {
      debugPrint('Failed to decrypt text, returning raw value: $error');
      return null;
    }
  }
}

