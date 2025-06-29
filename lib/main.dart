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
import 'repositories/autopsy_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/autopsy-list': (context) => const AutopsyListScreen(),
        '/autopsy-detail': (context) {
          final autopsyId = ModalRoute.of(context)!.settings.arguments as String;
          return AutopsyDetailScreen(autopsyId: autopsyId);
        },
        // Add other routes here
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Check if user is logged in and initialize permission service
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      if (isLoggedIn) {
        // Initialize enhanced autopsy client and permission service
        final crmBaseUrl = prefs.getString('crmDomain');
        if (crmBaseUrl != null) {
          // Initialize services here if needed
          // EnhancedAutopsyClient.instance.initialize(crmBaseUrl);
          
          // Pre-load permissions
          // await PermissionService.instance.getComputedPermissions();
        }
      }

      setState(() {
        _isAuthenticated = isLoggedIn;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthenticated) {
      return const MainNavigationScreen();
    } else {
      return const LoginScreen();
    }
  }
}

// Temporary placeholder for AutopsyListScreen
class AutopsyListScreen extends StatelessWidget {
  const AutopsyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AutopsyClient>(
          create: (_) => AutopsyClient(baseUrl: 'https://your-api-url.com'),
        ),
        ChangeNotifierProvider<PermissionsManager>(
          create: (_) => PermissionsManager(),
        ),
        ChangeNotifierProxyProvider<AutopsyClient, AutopsyRepository>(
          create: (context) => AutopsyRepository(
            client: context.read<AutopsyClient>(),
          ),
          update: (context, client, previous) =>
              previous ?? AutopsyRepository(client: client),
        ),
      ],
      child: const AutopsiesScreen(),
    );
  }
}