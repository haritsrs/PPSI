import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_exception.dart';

AppException toAppException(
  Object error, {
  String? fallbackMessage,
}) {
  if (error is AppException) {
    return error;
  }

  if (error is SocketException) {
    return OfflineException(
      'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.',
      details: error.message,
    );
  }

  if (error is TimeoutException) {
    return TimeoutRequestException(
      'Permintaan melebihi batas waktu. Silakan coba lagi.',
      details: error.message,
    );
  }

  if (error is FirebaseAuthException) {
    final message = error.message ?? fallbackMessage ?? 'Gagal memproses autentikasi.';
    if (error.code == 'network-request-failed') {
      return NetworkException(message, details: error.code);
    }
    if (error.code == 'user-not-found') {
      return NotFoundException(message, details: error.code);
    }
    if (error.code == 'wrong-password') {
      return UnauthorizedException(message, details: error.code);
    }
    return ServerException(message, details: error.code);
  }

  if (error is FirebaseException) {
    final message = error.message ?? fallbackMessage ?? 'Terjadi kesalahan pada layanan.';
    if (error.code == 'network-error') {
      return NetworkException(message, details: error.code);
    }
    return ServerException(message, details: error.code);
  }

  return AppException(
    fallbackMessage ?? 'Terjadi kesalahan tidak terduga. Silakan coba lagi.',
    details: error.toString(),
  );
}

String getFriendlyErrorMessage(Object error, {String? fallbackMessage}) {
  final appException = toAppException(error, fallbackMessage: fallbackMessage);
  return appException.message;
}

