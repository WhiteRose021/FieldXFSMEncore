// lib/app/routes.dart
import 'package:flutter/material.dart';
import '../screens/enhanced_login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/autopsies_screen.dart';
import '../screens/autopsy_detail_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String autopsies = '/autopsies';
  static const String autopsyDetail = '/autopsy-detail';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const EnhancedLoginScreen(),
          settings: settings,
        );
      
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      
      case '/autopsies':
        return MaterialPageRoute(
          builder: (_) => const AutopsiesScreen(),
          settings: settings,
        );
      
      case '/autopsy-detail':
        final autopsyId = settings.arguments as String?;
        if (autopsyId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Autopsy ID is required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => AutopsyDetailScreen(autopsyId: autopsyId),
          settings: settings,
        );
      
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const EnhancedLoginScreen(),
    dashboard: (context) => const DashboardScreen(),
    autopsies: (context) => const AutopsiesScreen(),
    settings: (context) => const SettingsScreen(),
  };

  // For app.dart compatibility
  static Map<String, WidgetBuilder> getRoutes() => routes;
}