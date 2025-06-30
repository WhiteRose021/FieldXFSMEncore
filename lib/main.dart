// lib/main.dart - Fixed version with proper BackendService initialization
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/autopsy_detail_screen.dart';
import 'screens/autopsies_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'services/backend_service.dart';
import 'services/autopsy_service.dart';
import 'services/permissions_manager.dart';
import 'services/auth_service.dart';
import 'repositories/autopsy_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app configuration
  await _initializeApp();
  
  runApp(const MyApp());
}

/// Initialize app configuration and BackendService
Future<void> _initializeApp() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Set default environment if not already set
  if (!prefs.containsKey('environment')) {
    await prefs.setString('environment', 'development');
  }
  
  // Set default tenant if not already set
  if (!prefs.containsKey('selectedTenant')) {
    await prefs.setString('selectedTenant', '');
  }
  
  // 🔥 KEY FIX: Initialize BackendService using BackendConfig
  await BackendService.instance.initialize();
  
  debugPrint('✅ App initialized');
  debugPrint('🚀 Initializing FieldX FSM services...');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Service - UPDATED: Initialize and check existing auth
        ChangeNotifierProvider<AuthService>(
          create: (_) {
            final authService = AuthService();
            // Initialize and check for existing authentication
            authService.initialize();
            return authService;
          },
        ),
        
        // Autopsy Service - FIXED: Remove baseUrl parameter
        Provider<AutopsyService>(
          create: (_) => AutopsyService(),
        ),
        
        // Permissions Manager
        ChangeNotifierProvider<PermissionsManager>(
          create: (_) => PermissionsManager(),
        ),
        
        // Autopsy Repository
        ChangeNotifierProxyProvider<AutopsyService, AutopsyRepository>(
          create: (context) => AutopsyRepository(
            client: context.read<AutopsyService>(),
          ),
          update: (context, client, previous) =>
              previous ?? AutopsyRepository(client: client),
        ),
      ],
      child: MaterialApp(
        title: 'FieldX FSM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          useMaterial3: true,
        ),
        
        home: const LoginScreen(),
        
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const MainNavigationScreen(),
          '/autopsies': (context) => const AutopsiesScreen(),
        },
        
        onGenerateRoute: (settings) {
          if (settings.name?.startsWith('/autopsy/') == true) {
            final autopsyId = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) => AutopsyDetailScreen(autopsyId: autopsyId),
            );
          }
          return null;
        },
      ),
    );
  }
}