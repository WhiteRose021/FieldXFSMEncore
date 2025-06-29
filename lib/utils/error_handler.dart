// lib/utils/error_handler.dart
import 'package:flutter/material.dart';
import '../models/autopsy_models.dart';

class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';
    
    if (error is AutopsyException) {
      message = error.message;
    } else if (error is Exception) {
      message = error.toString();
    } else if (error is String) {
      message = error;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
