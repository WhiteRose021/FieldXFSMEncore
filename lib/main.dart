// lib/main.dart - Enhanced version with permission integration
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
    await prefs.setString('selectedTenant', 'applink'); // Default to applink
  }
  
  // Initialize BackendService using BackendConfig
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
        // Auth Service - FIRST (others depend on it)
        ChangeNotifierProvider<AuthService>(
          create: (_) {
            final authService = AuthService();
            // Initialize and check for existing authentication
            authService.initialize();
            return authService;
          },
        ),
        
        // Permissions Manager - SECOND (depends on auth)
        ChangeNotifierProvider<PermissionsManager>(
          create: (_) => PermissionsManager(),
        ),
        
        // Autopsy Service
        Provider<AutopsyService>(
          create: (_) => AutopsyService(),
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
        
        // 🔥 ENHANCED: Use AuthenticationWrapper to handle session and permissions
        home: const AuthenticationWrapper(),
        
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

/// 🆕 NEW: Authentication wrapper that handles session and permission initialization
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _isInitializing = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  /// Initialize user session and permissions
  Future<void> _initializeSession() async {
    try {
      debugPrint('🔄 Initializing user session...');
      
      final authService = context.read<AuthService>();
      final permissionsManager = context.read<PermissionsManager>();
      
      // Wait for auth service to finish initialization
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if user is already authenticated
      final isAuthenticated = await authService.checkAuthentication();
      
      if (isAuthenticated) {
        debugPrint('✅ User is authenticated, initializing permissions...');
        
        // Initialize permissions for authenticated user
        await permissionsManager.initializeUserPermissions(authService);
        
        debugPrint('✅ Permissions initialized successfully');
        debugPrint('👤 User: ${authService.currentUser}');
        debugPrint('🏢 Tenant: ${authService.tenantName}');
        debugPrint('🔑 Can create: ${permissionsManager.canCreate}');
        debugPrint('🔑 Can edit: ${permissionsManager.canEdit}');
        debugPrint('🔑 Can delete: ${permissionsManager.canDelete}');
      } else {
        debugPrint('ℹ️ User not authenticated, will show login screen');
      }
      
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isInitializing = false;
      });
      
    } catch (error) {
      debugPrint('❌ Error initializing session: $error');
      setState(() {
        _isAuthenticated = false;
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing FieldX FSM...'),
            ],
          ),
        ),
      );
    }

    // Show appropriate screen based on authentication status
    if (_isAuthenticated) {
      return const MainNavigationScreen();
    } else {
      return const LoginScreen();
    }
  }
}

/// 🆕 NEW: Login success handler widget
class LoginSuccessHandler extends StatefulWidget {
  const LoginSuccessHandler({super.key});

  @override
  State<LoginSuccessHandler> createState() => _LoginSuccessHandlerState();
}

class _LoginSuccessHandlerState extends State<LoginSuccessHandler> {
  bool _isInitializingPermissions = true;

  @override
  void initState() {
    super.initState();
    _initializePermissionsAfterLogin();
  }

  Future<void> _initializePermissionsAfterLogin() async {
    try {
      debugPrint('🔐 Initializing permissions after successful login...');
      
      final authService = context.read<AuthService>();
      final permissionsManager = context.read<PermissionsManager>();
      
      // Initialize permissions for newly authenticated user
      await permissionsManager.initializeUserPermissions(authService);
      
      debugPrint('✅ Post-login permissions initialized');
      
      setState(() {
        _isInitializingPermissions = false;
      });
      
      // Navigate to main screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
      
    } catch (error) {
      debugPrint('❌ Error initializing permissions after login: $error');
      
      // Show error and return to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading permissions: $error'),
            backgroundColor: Colors.red,
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isInitializingPermissions 
                  ? 'Loading permissions...' 
                  : 'Redirecting...',
            ),
          ],
        ),
      ),
    );
  }
}