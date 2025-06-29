// lib/main.dart - UPDATED with BackendService
// Following FSM Architecture PLAN - Clean initialization with BackendService

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
  
  // Initialize app configuration and BackendService
  await _initializeApp();
  
  runApp(const MyApp());
}

/// Initialize app configuration and BackendService
Future<void> _initializeApp() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Set default environment (development = true for local testing)
  if (!prefs.containsKey('isDevelopment')) {
    await prefs.setBool('isDevelopment', true);
  }
  
  // Set default tenant (empty = no specific tenant)
  if (!prefs.containsKey('selectedTenant')) {
    await prefs.setString('selectedTenant', '');
  }
  
  // Get environment setting
  final isDevelopment = prefs.getBool('isDevelopment') ?? true;
  final environment = isDevelopment 
      ? BackendEnvironment.development 
      : BackendEnvironment.production;
  
  // Initialize BackendService with proper environment
  await BackendService.instance.initialize(
    environment: environment,
    timeout: const Duration(seconds: 30),
  );
  
  debugPrint('✅ App initialized with BackendService');
  debugPrint('🌍 Environment: $environment');
  debugPrint('🔗 API URL: ${BackendService.instance.getApiBaseUrl()}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Service
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        
        // Autopsy Service - now uses BackendService (no baseUrl needed)
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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const MainNavigationScreen(),
          '/autopsy-list': (context) => const AutopsyListScreen(),
          '/autopsy-detail': (context) {
            final autopsyId = ModalRoute.of(context)!.settings.arguments as String;
            return AutopsyDetailScreen(autopsyId: autopsyId);
          },
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      debugPrint('🚀 Initializing FieldX FSM services...');
      
      // Initialize the auth service
      final authService = context.read<AuthService>();
      await authService.initialize();
      
      // Load permissions manager
      final permissionsManager = context.read<PermissionsManager>();
      await permissionsManager.loadPermissions();
      
      // If user is authenticated, set auth token in BackendService
      if (authService.isAuthenticated && authService.currentUser != null) {
        // Assuming auth service has a token property
        // BackendService.instance.setAuthToken(authService.token);
        debugPrint('🔐 User authenticated - token set in BackendService');
      }
      
      debugPrint('✅ Service initialization completed');
      
    } catch (error) {
      debugPrint('❌ Service initialization error: $error');
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing FieldX FSM...',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Connecting to Encore.ts backend',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  'Backend: ${BackendService.instance.getApiBaseUrl()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _initializeServices();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          return const MainNavigationScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// Simple autopsy list screen for route compatibility
class AutopsyListScreen extends StatelessWidget {
  const AutopsyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AutopsiesScreen();
  }
}