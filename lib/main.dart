// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/autopsy_detail_screen.dart';
import 'screens/autopsies_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'services/autopsy_client.dart';
import 'services/permissions_manager.dart';
import 'services/auth_service.dart';
import 'services/authentication_service.dart';
import 'repositories/autopsy_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences and set default backend if not set
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('selectedBackend')) {
    await prefs.setString('selectedBackend', 'encore'); // Default to Encore
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Service
        Provider<AuthenticationService>(
          create: (_) => AuthenticationService(),
        ),
        
        // Auth Service with dependency injection
        ChangeNotifierProxyProvider<AuthenticationService, AuthService>(
          create: (context) => AuthService(
            authenticationService: context.read<AuthenticationService>(),
          ),
          update: (context, authService, previous) => previous ?? AuthService(
            authenticationService: authService,
          ),
        ),
        
        // Autopsy Client - will be configured based on backend
        Provider<AutopsyClient>(
          create: (_) => AutopsyClient(baseUrl: _getApiBaseUrl()),
        ),
        
        // Permissions Manager
        ChangeNotifierProvider<PermissionsManager>(
          create: (_) => PermissionsManager(),
        ),
        
        // Autopsy Repository
        ChangeNotifierProxyProvider<AutopsyClient, AutopsyRepository>(
          create: (context) => AutopsyRepository(
            client: context.read<AutopsyClient>(),
          ),
          update: (context, client, previous) =>
              previous ?? AutopsyRepository(client: client),
        ),
      ],
      child: MaterialApp(
        title: 'Field Management App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
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
      ),
    );
  }
  
  // Get API base URL based on selected backend
  static String _getApiBaseUrl() {
    // This will be updated dynamically based on backend selection
    // For now, return a default Encore URL
    return 'https://your-encore-app.encr.app'; // Replace with your actual Encore app URL
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize the auth service
      final authService = context.read<AuthService>();
      await authService.initialize();
      
      // Configure backend settings
      await _configureBackend();
      
    } catch (error) {
      debugPrint('App initialization error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _configureBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedBackend = prefs.getString('selectedBackend') ?? 'encore';
    
    if (selectedBackend == 'encore') {
      // Configure Encore backend
      await _configureEncoreBackend(prefs);
    } else {
      // Configure EspoCRM backend  
      await _configureEspoCRMBackend(prefs);
    }
  }

  Future<void> _configureEncoreBackend(SharedPreferences prefs) async {
    // Set default Encore configuration if not set
    if (!prefs.containsKey('encoreApiUrl')) {
      // Replace with your actual Encore app URL
      await prefs.setString('encoreApiUrl', 'https://your-encore-app.encr.app');
    }
    
    if (!prefs.containsKey('selectedTenant')) {
      // Set default tenant
      await prefs.setString('selectedTenant', 'default');
    }
    
    if (!prefs.containsKey('isDevelopment')) {
      // Set to true for development, false for production
      await prefs.setBool('isDevelopment', true);
    }
    
    debugPrint('✅ Encore backend configured');
  }

  Future<void> _configureEspoCRMBackend(SharedPreferences prefs) async {
    // EspoCRM configuration - keep existing logic
    if (!prefs.containsKey('crmDomain')) {
      await prefs.setString('crmDomain', 'https://your-espocrm-domain.com');
    }
    
    debugPrint('✅ EspoCRM backend configured');
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
              Text('Initializing app...'),
            ],
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

// Keep your existing AutopsyListScreen
class AutopsyListScreen extends StatelessWidget {
  const AutopsyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The providers are already available from the main app
    return const AutopsiesScreen();
  }
}