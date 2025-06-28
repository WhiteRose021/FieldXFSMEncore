import 'package:flutter/material.dart';

enum AppStatus {
  completed('ΟΛΟΚΛΗΡΩΣΗ'),
  pending('ΕΚΚΡΕΜΗΣ'),
  cancelled('ΑΚΥΡΩΣΗ'),
  processing('ΕΠΕΞΕΡΓΑΣΙΑ');
  
  const AppStatus(this.rawValue);
  final String rawValue;
  
  static AppStatus? fromString(String value) {
    for (AppStatus status in AppStatus.values) {
      if (status.rawValue.toUpperCase() == value.toUpperCase()) {
        return status;
      }
    }
    return null;
  }
}

extension AppStatusExtension on AppStatus {
  String get displayName {
    switch (this) {
      case AppStatus.completed:
        return 'Ολοκλήρωση';
      case AppStatus.pending:
        return 'Εκκρεμής';
      case AppStatus.cancelled:
        return 'Ακύρωση';
      case AppStatus.processing:
        return 'Επεξεργασία';
    }
  }
  
  Color get backgroundColor {
    switch (this) {
      case AppStatus.completed:
        return Colors.green.shade100;
      case AppStatus.pending:
        return Colors.orange.shade100;
      case AppStatus.cancelled:
        return Colors.red.shade100;
      case AppStatus.processing:
        return Colors.blue.shade100;
    }
  }
  
  Color get textColor {
    switch (this) {
      case AppStatus.completed:
        return Colors.green.shade800;
      case AppStatus.pending:
        return Colors.orange.shade800;
      case AppStatus.cancelled:
        return Colors.red.shade800;
      case AppStatus.processing:
        return Colors.blue.shade800;
    }
  }
}