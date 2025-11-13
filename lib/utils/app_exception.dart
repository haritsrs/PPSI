enum AppExceptionType {
  network,
  offline,
  timeout,
  rateLimit,
  unauthorized,
  validation,
  notFound,
  server,
  unknown,
}

class AppException implements Exception {
  const AppException(
    this.message, {
    this.type = AppExceptionType.unknown,
    this.details,
  });

  final AppExceptionType type;
  final String message;
  final String? details;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.network,
          details: details,
        );
}

class OfflineException extends AppException {
  const OfflineException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.offline,
          details: details,
        );
}

class TimeoutRequestException extends AppException {
  const TimeoutRequestException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.timeout,
          details: details,
        );
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.unauthorized,
          details: details,
        );
}

class RateLimitException extends AppException {
  const RateLimitException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.rateLimit,
          details: details,
        );
}

class ValidationException extends AppException {
  const ValidationException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.validation,
          details: details,
        );
}

class NotFoundException extends AppException {
  const NotFoundException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.notFound,
          details: details,
        );
}

class ServerException extends AppException {
  const ServerException(String message, {String? details})
      : super(
          message,
          type: AppExceptionType.server,
          details: details,
        );
}

