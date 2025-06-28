// lib/main.dart - Fixed version with no duplicate auth headers
import 'package:dio/dio.dart';
import 'package:fieldx_fsm/services/config_service.dart';
import 'package:fieldx_fsm/services/enhanced_unified_crm_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'widgets/status_label.dart';
import 'extensions/string_extensions.dart';
import 'utils/status_utils.dart';
import 'models/app_status.dart';

// Enhanced services import
import 'services/enhanced_service_adapters.dart';

// ADD THESE IMPORTS:
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/authentication_service.dart';
import 'services/permissions_manager.dart';
import 'services/autopsy_client.dart';
import 'repositories/autopsy_repository.dart';

// Global flag to prevent re-initialization during hot restarts
bool _isBackendInitialized = false;

// Authentication utility methods
class AuthUtils {
  static Future<bool> isUserAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    final userName = prefs.getString('userName');
    final userId = prefs.getString('userId');
    
    return authToken != null && 
           authToken.isNotEmpty && 
           userName != null && 
           userName.isNotEmpty &&
           userId != null && 
           userId.isNotEmpty;
  }
  
  static Future<Map<String, String?>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'authToken': prefs.getString('authToken'),
      'userName': prefs.getString('userName'),
      'userId': prefs.getString('userId'),
      'crmDomain': prefs.getString('crmDomain'),
    };
  }
  
  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }
  
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
  
  static Future<void> printAuthStatus() async {
    final userInfo = await getCurrentUser();
    final isAuth = await isUserAuthenticated();
    
    print("🔍 AUTH STATUS:");
    print("  Authenticated: $isAuth");
    print("  User: ${userInfo['userName']}");
    print("  Domain: ${userInfo['crmDomain']}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();
    print("✅ Hive initialized successfully");
    
    // IMPROVED: Only initialize backend if not already done
    await _initializeBackendManagerOnce();
    print("✅ Backend manager initialized");
    
  } catch (e) {
    print("⚠️ Initialization error: $e");
  }
  
  runApp(
    AppLifecycleManager(
      child: MyApp(),
    ),
  );
}

// IMPROVED: Initialize Backend Manager only once to prevent hot restart issues
Future<void> _initializeBackendManagerOnce() async {
  // Check if already initialized (prevents hot restart re-initialization)
  if (_isBackendInitialized) {
    print("🔄 Backend already initialized, skipping re-initialization");
    final currentBackend = BackendManager.getCurrentBackend();
    print("   Current backend: ${currentBackend.name}");
    return;
  }

  try {
    print("🚀 Starting backend initialization...");
    final prefs = await SharedPreferences.getInstance();
    
    // IMPROVED: Add detailed debugging for backend selection
    final savedBackendName = prefs.getString('selectedBackend');
    final savedTenant = prefs.getString('selectedTenant');
    final savedIsDev = prefs.getBool('isDevelopment');
    
    print("📋 Saved preferences:");
    print("   - Backend: '$savedBackendName'");
    print("   - Tenant: '$savedTenant'");
    print("   - IsDevelopment: $savedIsDev");
    
    // IMPROVED: More robust backend type detection
    BackendType backendType;
    if (savedBackendName != null && savedBackendName.isNotEmpty) {
      try {
        backendType = BackendType.values.firstWhere(
          (type) => type.name.toLowerCase() == savedBackendName.toLowerCase(),
        );
        print("✅ Found matching backend type: ${backendType.name}");
      } catch (e) {
        print("⚠️ Invalid saved backend '$savedBackendName', available backends: ${BackendType.values.map((e) => e.name).join(', ')}");
        // IMPROVED: Default to Encore instead of EspoCRM if no specific preference
        backendType = BackendType.encore;
        print("🔄 Defaulting to: ${backendType.name}");
      }
    } else {
      print("ℹ️ No saved backend preference found");
      // IMPROVED: Default to Encore for new installations
      backendType = BackendType.encore;
      print("🔄 Using default: ${backendType.name}");
    }
    
    final tenantCode = savedTenant;
    final isDevelopment = savedIsDev ?? true;
    
    print("🎯 Initializing backend with:");
    print("   - Type: ${backendType.name}");
    print("   - Tenant: $tenantCode");
    print("   - Development: $isDevelopment");
    
    // Initialize the backend
    await BackendManager.initializeApp(
      backendType: backendType,
      tenantCode: tenantCode,
      isDevelopment: isDevelopment,
    );
    
    // Mark as initialized to prevent re-initialization
    _isBackendInitialized = true;
    
    print("✅ Backend Manager initialized with ${backendType.name} backend");
    
    // IMPROVED: Save the backend settings to ensure consistency
    await prefs.setString('selectedBackend', backendType.name);
    if (tenantCode != null) {
      await prefs.setString('selectedTenant', tenantCode);
    }
    await prefs.setBool('isDevelopment', isDevelopment);
    
  } catch (e) {
    print("❌ Backend Manager initialization completely failed: $e");
    
    // IMPROVED: Only fallback if absolutely necessary and log it clearly
    print("🚨 Using emergency fallback to EspoCRM backend");
    
    try {
      await BackendManager.initializeApp(
        backendType: BackendType.espocrm,
        isDevelopment: true,
      );
      _isBackendInitialized = true;
      print("✅ Emergency fallback successful");
    } catch (fallbackError) {
      print("💥 Even fallback failed: $fallbackError");
      // Don't mark as initialized if fallback fails
    }
  }
}

// IMPROVED: Force backend re-initialization (for settings changes)
Future<void> forceBackendReinitialization() async {
  print("🔄 Forcing backend re-initialization...");
  _isBackendInitialized = false;
  await _initializeBackendManagerOnce();
}

// FIXED: Custom provider with simplified Dio that doesn't interfere with auth
class ServicesProvider extends StatelessWidget {
  final Widget child;

  const ServicesProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Create simplified Dio instance (no auth interceptor)
        Provider<Dio>(
          create: (_) => _createSimplifiedDio(),
          dispose: (_, dio) => dio.close(),
        ),
        
        // 2. Create AuthService
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(
            authenticationService: AuthenticationService(),
          ),
        ),
        
        // 3. Create AutopsyClient using the Dio instance
        Provider<AutopsyClient>(
          create: (context) => AutopsyClient(
            dio: context.read<Dio>(),
            debugMode: true,
          ),
        ),
        
        // 4. Create PermissionsManager using AutopsyClient
        ChangeNotifierProvider<PermissionsManager>(
          create: (context) => PermissionsManager(
            client: context.read<AutopsyClient>(),
          ),
        ),
        
        // 5. Create AutopsyRepository using AutopsyClient  
        ChangeNotifierProvider<AutopsyRepository>(
          create: (context) => AutopsyRepository(
            client: context.read<AutopsyClient>(),
          ),
        ),
      ],
      child: child,
    );
  }

  /// FIXED: Simplified Dio instance that doesn't interfere with EnhancedUnifiedCRMService auth
  Dio _createSimplifiedDio() {
    final dio = Dio();
    
    // Configure base URL based on your backend
    final baseUrl = BackendManager.isUsingEncore() 
        ? 'http://192.168.4.20:4002' // Your Encore URL
        : 'http://localhost:8080';   // Your EspoCRM URL
    
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // REMOVED: Auth interceptor - let EnhancedUnifiedCRMService handle all auth
    // Only add basic headers that don't conflict
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Only add basic headers, no auth headers
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          options.headers['User-Agent'] = 'FieldX-Flutter-App/1.0.0';
          
          print("🌐 Dio request to: ${options.uri}");
          print("📋 Headers: ${options.headers.keys.join(', ')}");
          
          handler.next(options);
        } catch (e) {
          print("⚠️ Error in Dio interceptor: $e");
          handler.next(options);
        }
      },
      onResponse: (response, handler) {
        print("📨 Dio response: ${response.statusCode} from ${response.requestOptions.uri}");
        handler.next(response);
      },
      onError: (error, handler) {
        print("❌ Dio error: ${error.response?.statusCode} - ${error.message}");
        handler.next(error);
      },
    ));
    
    return dio;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ServicesProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FieldX FSM',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
            actionsIconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            elevation: 4,
          ),
        ),
        home: const AuthCheckScreen(),
        routes: {
          '/login': (context) => const EnhancedLoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

// AuthCheckScreen with comprehensive auto-login
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  String _initializationStatus = "Checking authentication...";
  bool _isInitializing = true;
  
  @override
  void initState() {
    super.initState();
    _performAutoLoginAndInitialization();
  }

  Future<void> _performAutoLoginAndInitialization() async {
    try {
      // Step 1: Check if user is logged in
      setState(() => _initializationStatus = "Checking authentication...");
      
      if (!await AuthUtils.isUserAuthenticated()) {
        debugPrint("❌ User not authenticated, redirecting to login");
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EnhancedLoginScreen()),
          );
        }
        return;
      }

      // User is authenticated - start full initialization
      final userName = await AuthUtils.getCurrentUserName();
      debugPrint("✅ User authenticated: $userName");
      
      setState(() => _initializationStatus = "Initializing services...");
      
      // Initialize enhanced services
      await _initializeEnhancedServices();
      
      // Initialize WebSocket for real-time updates
      await _initializeWebSocket();
      
      setState(() => _initializationStatus = "Loading dashboard...");
      
      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
      
    } catch (e) {
      debugPrint("❌ Auth/Init error: $e");
      setState(() => _initializationStatus = "Initialization failed. Redirecting to login...");
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EnhancedLoginScreen()),
        );
      }
    }
  }

  Future<void> _initializeEnhancedServices() async {
    try {
      debugPrint("🚀 Initializing enhanced services...");
      
      final enhancedService = EnhancedUnifiedCRMService.instance;
      
      // Initialize metadata
      await enhancedService.fetchMetadata();
      debugPrint("✅ Enhanced metadata initialized");
      
      // Initialize appointments
      await enhancedService.fetchTechnicianAppointments();
      debugPrint("✅ Enhanced appointments initialized");
      
    } catch (e) {
      debugPrint("⚠️ Enhanced services initialization failed: $e");
      // Continue anyway - services will retry automatically
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      if (!await AuthUtils.isUserAuthenticated()) {
        debugPrint("🔌 User not authenticated, skipping WebSocket initialization");
        return;
      }
      
      final userName = await AuthUtils.getCurrentUserName();
      debugPrint("🔌 Initializing WebSocket for authenticated user: $userName");
      
    } catch (e) {
      debugPrint("⚠️ WebSocket initialization failed: $e");
      // Continue anyway - WebSocket will try to reconnect automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.settings_applications,
              size: 64,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 24),
            
            // App title
            Text(
              "FieldX FSM",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 32),
            
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            
            // Status text
            Text(
              _initializationStatus,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Backend indicator with current status
            Text(
              "Backend: ${BackendManager.getCurrentBackend().name.toUpperCase()}${_isBackendInitialized ? ' (Initialized)' : ' (Initializing...)'}",
              style: TextStyle(
                fontSize: 12,
                color: BackendManager.isUsingEncore() 
                  ? Colors.blue
                  : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            // Show auth token status for debugging
            FutureBuilder<String?>(
              future: AuthUtils.getCurrentUser().then((user) => user['authToken']),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final token = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Token: ${token.length > 10 ? '${token.substring(0, 10)}...' : token}",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// App lifecycle manager to handle app state changes and refresh services
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  _AppLifecycleManagerState createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // Refresh services when app comes back to foreground
      _refreshServicesOnResume();
    }
  }

  void _refreshServicesOnResume() {
    Future.delayed(Duration.zero, () async {
      try {
        if (await AuthUtils.isUserAuthenticated()) {
          debugPrint("🔄 App resumed - refreshing enhanced CRM services");
          final enhancedService = EnhancedUnifiedCRMService.instance;
          
          // Refresh services in background (non-blocking)
          enhancedService.fetchMetadata().catchError((e) {
            debugPrint("⚠️ Background metadata refresh failed: $e");
          });
          
          enhancedService.fetchTechnicianAppointments().catchError((e) {
            debugPrint("⚠️ Background appointments refresh failed: $e");
          });
        }
      } catch (e) {
        debugPrint("⚠️ Error refreshing enhanced CRM services in background: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}