import 'package:flutter/material.dart';

class StatusUtils {
  static const Map<String, StatusStyle> _statusMap = {
    'ΟΛΟΚΛΗΡΩΣΗ': StatusStyle(
      displayText: 'Ολοκλήρωση',
      backgroundColor: Color(0xFF4CAF50),
      textColor: Colors.white,
    ),
    'ΑΠΟΣΤΟΛΗ': StatusStyle(
      displayText: 'Αποστολή',
      backgroundColor: Color(0xFFFF9800),
      textColor: Colors.white,
    ),
    'ΜΗ ΟΛΟΚΛΗΡΩΣΗ': StatusStyle(
      displayText: 'Μη Ολοκλήρωση',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    ),
    'ΑΠΟΡΡΙΨΗ': StatusStyle(
      displayText: 'Απόρριψη',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    ),
    'ΕΚΚΡΕΜΗΣ': StatusStyle(
      displayText: 'Εκκρεμής',
      backgroundColor: Color(0xFF666666),
      textColor: Colors.white,
    ),
  };
  
  static Widget buildStatusWidget(String status) {
    final statusStyle = _statusMap[status.toUpperCase()];
    
    if (statusStyle == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF666666),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusStyle.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusStyle.displayText,
        style: TextStyle(
          color: statusStyle.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  static String getDisplayText(String status) {
    return _statusMap[status.toUpperCase()]?.displayText ?? status;
  }
}

class StatusStyle {
  final String displayText;
  final Color backgroundColor;
  final Color textColor;
  
  const StatusStyle({
    required this.displayText,
    required this.backgroundColor,
    required this.textColor,
  });
}