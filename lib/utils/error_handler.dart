// lib/utils/error_handler.dart
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class ErrorHandler {
  /// Safely shows an error SnackBar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    try {
      // Ensure we're in a context where ScaffoldMessenger is available
      if (!context.mounted) {
        developer.log('❌ Context not mounted, cannot show SnackBar', name: 'ErrorHandler');
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        developer.log('❌ No ScaffoldMessenger found in context', name: 'ErrorHandler');
        return;
      }

      String errorMessage = _extractErrorMessage(error);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );

      // Also log the error
      developer.log('🚨 Error shown to user: $errorMessage', name: 'ErrorHandler');
    } catch (e) {
      developer.log('❌ Failed to show error SnackBar: $e', name: 'ErrorHandler');
    }
  }

  /// Shows a success SnackBar
  static void showSuccessSnackBar(BuildContext context, String message) {
    try {
      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      developer.log('❌ Failed to show success SnackBar: $e', name: 'ErrorHandler');
    }
  }

  /// Shows an info SnackBar
  static void showInfoSnackBar(BuildContext context, String message) {
    try {
      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue[600],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      developer.log('❌ Failed to show info SnackBar: $e', name: 'ErrorHandler');
    }
  }

  /// Shows an error dialog for more serious errors
  static Future<void> showErrorDialog(
    BuildContext context, 
    String title, 
    dynamic error,
  ) async {
    try {
      if (!context.mounted) return;

      String errorMessage = _extractErrorMessage(error);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(errorMessage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      developer.log('❌ Failed to show error dialog: $e', name: 'ErrorHandler');
    }
  }

  /// Extracts a user-friendly error message from various error types
  static String _extractErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    // Handle different error types
    if (error is String) {
      return error;
    }

    // Handle custom autopsy exceptions (if you have them)
    if (error.toString().contains('AutopsyPermissionException')) {
      return 'Permission denied. You don\'t have access to this resource.';
    }

    if (error.toString().contains('AutopsyNotFoundException')) {
      return 'The requested autopsy was not found.';
    }

    if (error.toString().contains('DioException') || error.toString().contains('DioError')) {
      return _extractDioError(error);
    }

    // Handle other common Flutter/Dart exceptions
    if (error.toString().contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    if (error.toString().contains('FormatException')) {
      return 'Invalid data format received from server.';
    }

    // Default fallback
    return 'An error occurred: ${error.toString()}';
  }

  /// Extracts error message from Dio exceptions
  static String _extractDioError(dynamic error) {
    try {
      final errorString = error.toString();
      
      if (errorString.contains('type \'Null\' is not a subtype')) {
        return 'Invalid data received from server';
      }
      
      if (errorString.contains('Connection refused')) {
        return 'Cannot connect to server. Please check if the server is running.';
      }
      
      if (errorString.contains('Connection timed out')) {
        return 'Connection timed out. Please try again.';
      }
      
      if (errorString.contains('No address associated with hostname')) {
        return 'Server not found. Please check the server URL.';
      }

      // Try to extract HTTP status codes
      if (errorString.contains('404')) {
        return 'Resource not found (404)';
      }
      
      if (errorString.contains('401')) {
        return 'Authentication required (401)';
      }
      
      if (errorString.contains('403')) {
        return 'Access forbidden (403)';
      }
      
      if (errorString.contains('500')) {
        return 'Server error (500)';
      }

      return 'Network error occurred';
    } catch (e) {
      return 'Network error occurred';
    }
  }

  /// Logs error details for debugging
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    developer.log(
      '❌ Error in $context: $error',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );
  }
}