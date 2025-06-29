// lib/exceptions/autopsy_exceptions.dart

class AutopsyPermissionException implements Exception {
  final String message;
  
  const AutopsyPermissionException(this.message);
  
  @override
  String toString() => 'AutopsyPermissionException: $message';
}
