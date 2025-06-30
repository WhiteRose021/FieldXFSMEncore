// lib/exceptions/autopsy_exceptions.dart - FIXED VERSION
// Prevents duplicate import issues

/// Base autopsy exception
class AutopsyException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AutopsyException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AutopsyException: $message';
}

/// Autopsy not found exception
class AutopsyNotFoundException extends AutopsyException {
  AutopsyNotFoundException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'not_found',
          originalError: originalError,
        );
}

/// Permission denied exception - FIXED: Single definition
class AutopsyPermissionException extends AutopsyException {
  AutopsyPermissionException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'permission_denied',
          originalError: originalError,
        );
}

/// Validation error exception
class AutopsyValidationException extends AutopsyException {
  final Map<String, List<String>>? fieldErrors;

  AutopsyValidationException({
    required String message,
    this.fieldErrors,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'validation_error',
          originalError: originalError,
        );
}

/// Network error exception
class AutopsyNetworkException extends AutopsyException {
  final int? statusCode;

  AutopsyNetworkException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'network_error',
          originalError: originalError,
        );
}