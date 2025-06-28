import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/settings_screen.dart';

// import '../screens/warehouse_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String appointments = '/appointments';
  static const String constructAppointments = '/construct-appointments'; 
  static const String constructionsList = '/constructions-list'; // Add new route
  static const String map = '/maps';
  static const String settings = '/settings';
  static const String building = '/building';
  static const String warehouse = '/warehouse';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const EnhancedLoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      settings: (context) => const SettingsScreen(),
      // warehouse: (context) => const WarehouseScreen(),
    };
  }
}