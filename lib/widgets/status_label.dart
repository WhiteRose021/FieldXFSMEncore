import 'package:flutter/material.dart';

class StatusLabel extends StatelessWidget {
  final String status;
  final double? fontSize;
  final EdgeInsets? padding;
  
  const StatusLabel({
    Key? key, 
    required this.status,
    this.fontSize = 14,
    this.padding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final transformedStatus = _transformStatus(status);
    final config = _getStatusConfig(status);
    
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20), // Keep your original border radius
        border: Border.all(color: config.borderColor),
      ),
      child: Text(
        transformedStatus,
        style: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w600, // Keep your original font weight
          fontSize: fontSize,
        ),
      ),
    );
  }
  
  String _transformStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ΟΛΟΚΛΗΡΩΣΗ':
        return 'Ολοκλήρωση';
      case 'ΑΠΟΣΤΟΛΗ':
        return 'Αποστολή';
      case 'ΜΗ ΟΛΟΚΛΗΡΩΣΗ':
        return 'Μη Ολοκλήρωση';
      case 'ΑΠΟΡΡΙΨΗ':
        return 'Απόρριψη';
      case 'ΕΚΚΡΕΜΗΣ':
        return 'Εκκρεμής';
      case 'ΕΠΕΞΕΡΓΑΣΙΑ':
        return 'Επεξεργασία';
      default:
        return status.toLowerCase().replaceFirstMapped(
          RegExp(r'^\w'),
          (match) => match.group(0)!.toUpperCase(),
        );
    }
  }
  
  _StatusConfig _getStatusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'ΟΛΟΚΛΗΡΩΣΗ':
        return _StatusConfig(
          backgroundColor: const Color(0xFF4CAF50), // Your exact green
          borderColor: const Color(0xFF4CAF50),
          textColor: Colors.white, // White text like your original
        );
      case 'ΑΠΟΣΤΟΛΗ':
        return _StatusConfig(
          backgroundColor: const Color(0xFFFF9800), // Your exact orange
          borderColor: const Color(0xFFFF9800),
          textColor: Colors.white, // White text like your original
        );
      case 'ΜΗ ΟΛΟΚΛΗΡΩΣΗ':
      case 'ΑΠΟΡΡΙΨΗ':
        return _StatusConfig(
          backgroundColor: Colors.red, // Your exact red
          borderColor: Colors.red,
          textColor: Colors.white, // White text like your original
        );
      default:
        return _StatusConfig(
          backgroundColor: const Color(0xFF666666), // Your exact grey
          borderColor: const Color(0xFF666666),
          textColor: Colors.white, // White text like your original
        );
    }
  }
}

class _StatusConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  
  _StatusConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}