// lib/screens/enhanced_login_screen.dart - Fixed version with better error handling
import 'package:fieldx_fsm/services/enhanced_unified_crm_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/authentication_service.dart';
import '../services/enhanced_service_adapters.dart';
import 'fetch_data_screen.dart';
import 'enhanced_settings_screen.dart';

class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  _EnhancedLoginScreenState createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final _formKey = GlobalKey<FormState>();
  
  bool isLoading = false;
  bool isPasswordObscured = true;
  String? _backendStatus;
  String? _errorMessage;
  bool _rememberMe = false;
  
  // Animation controllers - initialized as nullable first
  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Backend and tenant selection
  BackendType _selectedBackend = BackendType.espocrm;
  String? _selectedTenant;
  bool _isDevelopment = true;
  
  // Available tenants for Encore
  final List<Map<String, String>> _availableTenants = [
    {'code': 'applink', 'name': 'AppLink Technologies', 'port': '4001'},
    {'code': 'beyond', 'name': 'Beyond Networks', 'port': '4002'},
    {'code': 'demo', 'name': 'Demo Environment', 'port': '4003'},
    {'code': 'test', 'name': 'Test Environment', 'port': '4004'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations immediately
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController!, curve: Curves.easeOutBack));
    
    _loadSavedSettings();
    _initializeBackend();
    
    // Start animations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController?.forward();
      _slideController?.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    usernameController.dispose();
    passwordController.dispose();
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print("📱 App resumed from background");
        break;
      case AppLifecycleState.paused:
        print("📱 App paused (going to background)");
        break;
      case AppLifecycleState.inactive:
        print("📱 App inactive");
        break;
      case AppLifecycleState.detached:
        print("📱 App detached");
        break;
      default:
        break;
    }
  }

  /// Load saved login settings
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Load saved username and remember me setting
      final savedUsername = prefs.getString('saved_username');
      final shouldRemember = prefs.getBool('remember_me') ?? false;
      
      if (savedUsername != null && shouldRemember) {
        usernameController.text = savedUsername;
        _rememberMe = shouldRemember;
      }
      
      // Load backend preferences
      _selectedBackend = BackendType.values.firstWhere(
        (type) => type.name == prefs.getString('selectedBackend'),
        orElse: () => BackendType.espocrm,
      );
      
      _selectedTenant = prefs.getString('selectedTenant');
      _isDevelopment = prefs.getBool('isDevelopment') ?? true;
    });
    
    print("📋 Settings loaded - Backend: ${_selectedBackend.name}, Tenant: $_selectedTenant");
  }

  /// Initialize backend based on saved settings
  Future<void> _initializeBackend() async {
    try {
      await BackendManager.initializeApp(
        backendType: _selectedBackend,
        tenantCode: _selectedTenant,
        isDevelopment: _isDevelopment,
      );
      
      // Test backend connectivity
      await _testBackendConnection();
      
    } catch (e) {
      setState(() {
        _backendStatus = "Σφάλμα αρχικοποίησης backend: $e";
      });
      print("❌ Backend initialization failed: $e");
    }
  }

  /// Test backend connection and health
  Future<void> _testBackendConnection() async {
    if (_selectedBackend != BackendType.encore) {
      setState(() {
        _backendStatus = "Backend: ${_selectedBackend.name}${_selectedTenant != null ? ' (Tenant: $_selectedTenant)' : ''}";
      });
      return;
    }

    try {
      final enhancedService = EnhancedUnifiedCRMService.instance;
      final baseUrl = await enhancedService.getActiveBaseUrl();
      
      if (baseUrl == null) {
        throw Exception("Δεν έχει ρυθμιστεί URL backend");
      }

      print("🔍 Testing backend connection to: $baseUrl");

      // Test basic connectivity
      final healthUrl = Uri.parse('$baseUrl/health');
      final response = await http.get(
        healthUrl,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FieldX-Flutter-App/1.0.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _backendStatus = "✅ Backend συνδεδεμένο: ${_selectedBackend.name}${_selectedTenant != null ? ' (Tenant: $_selectedTenant)' : ''}";
        });
        print("✅ Backend health check passed");
      } else {
        throw Exception("Health check failed (${response.statusCode})");
      }
      
    } catch (e) {
      print("⚠️ Backend connection test failed: $e");
      
      // Try alternative health check endpoints
      await _tryAlternativeHealthCheck();
    }
  }

  /// Try alternative health check endpoints
  Future<void> _tryAlternativeHealthCheck() async {
    try {
      final enhancedService = EnhancedUnifiedCRMService.instance;
      final baseUrl = await enhancedService.getActiveBaseUrl();
      
      if (baseUrl == null) return;

      // Try different health check endpoints
      final endpoints = ['/ping', '/status', '/api/health', '/'];
      
      for (String endpoint in endpoints) {
        try {
          final testUrl = Uri.parse('$baseUrl$endpoint');
          final response = await http.get(
            testUrl,
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode < 500) {
            setState(() {
              _backendStatus = "⚠️ Backend βρέθηκε αλλά μπορεί να έχει προβλήματα (${_selectedBackend.name})";
            });
            print("⚠️ Backend responding but may have issues");
            return;
          }
        } catch (e) {
          continue;
        }
      }
      
      setState(() {
        _backendStatus = "❌ Backend μη διαθέσιμο (${_selectedBackend.name})${_selectedTenant != null ? ' - Tenant: $_selectedTenant' : ''}";
      });
      
    } catch (e) {
      setState(() {
        _backendStatus = "❌ Σφάλμα σύνδεσης backend: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}";
      });
    }
  }

  /// Save backend and tenant selection
  Future<void> _saveBackendSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('selectedBackend', _selectedBackend.name);
    if (_selectedTenant != null) {
      await prefs.setString('selectedTenant', _selectedTenant!);
    } else {
      await prefs.remove('selectedTenant');
    }
    await prefs.setBool('isDevelopment', _isDevelopment);
    
    // Reinitialize backend with new settings
    await _initializeBackend();
  }

  /// Save login credentials if remember me is checked
  Future<void> _saveCredentials(String username) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_username', username);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_username');
      await prefs.setBool('remember_me', false);
    }
  }

  /// IMPROVED: Perform Encore login with better error handling and fallback
  Future<Map<String, dynamic>> _performEncoreLogin(String username, String password) async {
    try {
      // Get the Encore service instance
      final enhancedService = EnhancedUnifiedCRMService.instance;
      final baseUrl = await enhancedService.getActiveBaseUrl();
      
      if (baseUrl == null) {
        throw Exception("Δεν έχει ρυθμιστεί URL backend Encore");
      }

      print("📡 Attempting Encore authentication with improved error handling");
      print("   - URL: $baseUrl");
      print("   - Username: $username");
      print("   - Tenant: $_selectedTenant");

      // IMPROVEMENT: Try multiple authentication endpoints/methods
      final authAttempts = [
        _attemptStandardEncoreAuth(baseUrl, username, password),
        _attemptLegacyAuthFormat(baseUrl, username, password),
        _attemptSimpleAuth(baseUrl, username, password),
      ];

      Exception? lastException;
      
      for (int i = 0; i < authAttempts.length; i++) {
        try {
          print("🔄 Authentication attempt ${i + 1}/3");
          final result = await authAttempts[i];
          print("✅ Authentication successful on attempt ${i + 1}");
          return result;
        } catch (e) {
          lastException = e as Exception;
          print("❌ Authentication attempt ${i + 1} failed: $e");
          
          // Wait a bit before next attempt
          if (i < authAttempts.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      // All attempts failed
      throw lastException ?? Exception("All authentication attempts failed");
      
    } catch (e) {
      print("❌ Encore login completely failed: $e");
      
      // IMPROVEMENT: Provide more specific error messages
      if (e.toString().contains('currentRequest is not a function')) {
        throw Exception("Πρόβλημα με τον Encore server. Ο server χρειάζεται επανεκκίνηση ή ενημέρωση.\n\nΤεχνικές λεπτομέρειες: Authentication service error");
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        throw Exception("Η σύνδεση έληξε. Ελέγξτε τη σύνδεση δικτύου και δοκιμάστε ξανά.");
      } else if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception("Δεν είναι δυνατή η σύνδεση με τον server. Ελέγξτε:\n• Τη σύνδεση δικτύου\n• Τη διεύθυνση server\n• Αν ο server λειτουργεί");
      } else {
        rethrow;
      }
    }
  }

  /// IMPROVEMENT: Standard Encore authentication
  Future<Map<String, dynamic>> _attemptStandardEncoreAuth(String baseUrl, String username, String password) async {
    final body = {
      'username': username.trim(),
      'password': password,
    };

    // Add subdomain/tenant if selected
    if (_selectedTenant != null && _selectedTenant!.isNotEmpty) {
      body['subdomain'] = _selectedTenant!;
    }

    final url = Uri.parse('$baseUrl/auth/login');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'User-Agent': 'FieldX-Flutter-App/1.0.0',
        'X-Client-Version': '1.0.0',
        'X-Platform': 'Flutter',
        if (_selectedTenant != null) 'X-Tenant-Code': _selectedTenant!,
      },
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));

    return _processAuthResponse(response, 'Standard Auth');
  }

  /// IMPROVEMENT: Legacy authentication format
  Future<Map<String, dynamic>> _attemptLegacyAuthFormat(String baseUrl, String username, String password) async {
    final body = {
      'user': username.trim(),
      'pass': password,
      'tenant': _selectedTenant ?? 'default',
    };

    final url = Uri.parse('$baseUrl/login');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));

    return _processAuthResponse(response, 'Legacy Auth');
  }

  /// IMPROVEMENT: Simple authentication format
  Future<Map<String, dynamic>> _attemptSimpleAuth(String baseUrl, String username, String password) async {
    final body = {
      'username': username.trim(),
      'password': password,
    };

    final url = Uri.parse('$baseUrl/api/auth');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));

    return _processAuthResponse(response, 'Simple Auth');
  }

  /// IMPROVEMENT: Process authentication response with better error handling
  Map<String, dynamic> _processAuthResponse(http.Response response, String authMethod) {
    print("📨 $authMethod response:");
    print("   - Status: ${response.statusCode}");
    print("   - Headers: ${response.headers}");
    print("   - Body length: ${response.body.length}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      print("✅ $authMethod successful:");
      print("   - Response keys: ${data.keys.join(', ')}");
      
      return data;
    } else {
      // Enhanced error handling for different status codes
      String errorMessage = 'Σφάλμα σύνδεσης';
      String technicalDetails = '';
      
      try {
        final errorData = json.decode(response.body);
        print("❌ $authMethod Error response data: $errorData");
        
        // Check for specific backend error patterns
        if (errorData['internal_message'] != null && 
            errorData['internal_message'].toString().contains('currentRequest is not a function')) {
          throw Exception("Backend server error: Authentication service needs restart");
        }
        
        errorMessage = errorData['message'] ?? errorData['error'] ?? 'Άγνωστο σφάλμα';
        technicalDetails = errorData['details'] ?? errorData['internal_message'] ?? '';
      } catch (e) {
        print("❌ Cannot parse $authMethod error response: $e");
        technicalDetails = response.body.isNotEmpty ? response.body : 'Κενή απάντηση από server';
      }

      // Specific error messages based on status code
      switch (response.statusCode) {
        case 400:
          errorMessage = 'Λανθασμένα στοιχεία σύνδεσης. Ελέγξτε το όνομα χρήστη και τον κωδικό.';
          break;
        case 401:
          errorMessage = 'Λάθος όνομα χρήστη ή κωδικός πρόσβασης.';
          break;
        case 403:
          errorMessage = 'Δεν έχετε δικαίωμα πρόσβασης σε αυτόν τον tenant.';
          break;
        case 404:
          errorMessage = 'Ο authentication endpoint δεν βρέθηκε. Ελέγξτε τις ρυθμίσεις σύνδεσης.';
          break;
        case 429:
          errorMessage = 'Πολλές προσπάθειες σύνδεσης. Δοκιμάστε ξανά σε λίγο.';
          break;
        case 500:
          if (technicalDetails.contains('currentRequest is not a function')) {
            errorMessage = 'Πρόβλημα με τον Encore server. Χρειάζεται επανεκκίνηση.';
            technicalDetails = 'Backend authentication service error - server needs restart';
          } else {
            errorMessage = 'Σφάλμα στον server. Επικοινωνήστε με τον διαχειριστή.';
          }
          break;
        case 502:
          errorMessage = 'Ο server δεν είναι διαθέσιμος. Δοκιμάστε ξανά.';
          break;
        case 503:
          errorMessage = 'Ο server είναι προσωρινά μη διαθέσιμος.';
          break;
        default:
          errorMessage = 'Σφάλμα σύνδεσης (${response.statusCode})';
      }

      print("❌ $authMethod failed:");
      print("   - Status: ${response.statusCode}");
      print("   - Error: $errorMessage");
      print("   - Technical: $technicalDetails");
      
      throw Exception("$errorMessage${technicalDetails.isNotEmpty ? '\n\nΤεχνικές λεπτομέρειες: $technicalDetails' : ''}");
    }
  }

  /// Store Encore user data (unchanged)
  Future<void> _storeEncoreUserData(Map<String, dynamic> loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Extract user data from Encore response
      final user = loginResponse['user'];
      final permissions = user['permissions'];
      final tenant = user['tenant'];
      
      // Store basic user info
      await prefs.setString('userId', user['id'] ?? '');
      await prefs.setString('userName', user['username'] ?? '');
      await prefs.setString('userType', user['type'] ?? 'regular');
      await prefs.setString('firstName', user['firstName'] ?? '');
      await prefs.setString('lastName', user['lastName'] ?? '');
      
      // Store authentication tokens
      await prefs.setString('authToken', loginResponse['token'] ?? '');
      await prefs.setString('sessionId', loginResponse['sessionId'] ?? '');
      
      // Store tenant information
      if (tenant != null) {
        await prefs.setString('tenantId', tenant['id'] ?? '');
        await prefs.setString('tenantName', tenant['name'] ?? tenant['displayName'] ?? '');
        await prefs.setString('tenantCode', tenant['tenantCode'] ?? '');
      } else {
        await prefs.setString('tenantId', user['tenantId'] ?? '');
        await prefs.setString('tenantName', user['tenantName'] ?? '');
      }
      
      // Store permissions
      if (permissions != null) {
        await prefs.setBool('isAdmin', permissions['isAdmin'] ?? false);
        await prefs.setBool('isSuperAdmin', permissions['isSuperAdmin'] ?? false);
        await prefs.setBool('canExport', permissions['canExport'] ?? false);
        await prefs.setBool('canMassUpdate', permissions['canMassUpdate'] ?? false);
        await prefs.setBool('canAudit', permissions['canAudit'] ?? false);
        await prefs.setBool('canManageUsers', permissions['canManageUsers'] ?? false);
      }
      
      // Set dummy roles and teams for now
      await prefs.setStringList('teamNames', ['Default Team']);
      await prefs.setStringList('roleNames', [user['type'] ?? 'User']);
      
      // Set technician flags
      await prefs.setBool('isTechnicianAutopsy', permissions?['isAdmin'] ?? false);
      await prefs.setBool('isTechnicianSplicer', permissions?['canExport'] ?? false);
      await prefs.setBool('isTechnicianConstruct', permissions?['canMassUpdate'] ?? false);
      await prefs.setBool('isTechnicianEarthworker', permissions?['canAudit'] ?? false);
      
      print("💾 Encore user data stored successfully");
      
    } catch (e) {
      print("❌ Error storing Encore user data: $e");
      rethrow;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    print("🔑 Login button pressed");
    
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });
    
    // Hide keyboard first
    FocusScope.of(context).unfocus();
    
    // Get input values
    final String username = usernameController.text.trim();
    final String password = passwordController.text;
    
    print("👤 Username entered: $username");
    print("🔒 Password entered (masked): ${password.replaceAll(RegExp(r'.'), '*')}");
    print("🌐 Current backend: ${BackendManager.getCurrentBackend().name}");
    print("🏢 Current tenant: $_selectedTenant");

    // Validate tenant selection for Encore backend
    if (_selectedBackend == BackendType.encore && _selectedTenant == null) {
      print("❌ No tenant selected for Encore backend");
      _showError("Please select a tenant for Encore backend.");
      return;
    }

    try {
      if (_selectedBackend == BackendType.encore) {
        // Use Encore authentication with improved error handling
        print("🎯 Performing Encore authentication with improved error handling");
        final loginResponse = await _performEncoreLogin(username, password);
        
        // Store user data
        await _storeEncoreUserData(loginResponse);
        
        final user = loginResponse['user'];
        final permissions = user['permissions'];
        
        print("✅ Encore authentication successful:");
        print("   - User: ${user['username']} (${user['type']})");
        print("   - Tenant: ${user['tenantName']}");
        print("   - Admin: ${permissions['isAdmin']}");
        print("   - Super Admin: ${permissions['isSuperAdmin']}");
        
      } else {
        // Use EspoCRM authentication through the BackendManager
        print("🎯 Performing EspoCRM authentication");
        final authResult = await BackendManager.login(username, password);
        print("✅ EspoCRM authentication successful: $authResult");
      }
      
      // Save credentials if remember me is checked
      await _saveCredentials(username);
      
      // Load and display user data from SharedPreferences
      await _loadAndDisplayUserData();
      
      // Navigate to dashboard
      _navigateToFetchDataScreen();
      
    } catch (e) {
      print("❌ Login failed: $e");
      String errorMessage = _getErrorMessage(e);
      _showError(errorMessage);
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // IMPROVEMENT: Better error message handling
    if (errorStr.contains('currentrequest is not a function') || 
        errorStr.contains('authentication service error') ||
        errorStr.contains('backend server error')) {
      return "Πρόβλημα με τον Encore server. Ο server χρειάζεται επανεκκίνηση.\n\nΠαρακαλώ επικοινωνήστε με τον διαχειριστή.";
    } else if (errorStr.contains('unauthorized') || errorStr.contains('invalid credentials')) {
      return "Invalid username or password";
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return "Network error. Please check your connection.";
    } else if (errorStr.contains('timeout')) {
      return "Request timeout. Please try again.";
    } else if (errorStr.contains('tenant')) {
      return "Invalid tenant selection. Please check your tenant settings.";
    } else {
      return "Login failed. Please try again.";
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      isLoading = false;
    });
  }

  Future<void> _loadAndDisplayUserData() async {
    final SharedPreferences userPrefs = await SharedPreferences.getInstance();
    
    bool isTechnicianAutopsy = userPrefs.getBool('isTechnicianAutopsy') ?? false;
    bool isTechnicianSplicer = userPrefs.getBool('isTechnicianSplicer') ?? false;
    bool isTechnicianConstruct = userPrefs.getBool('isTechnicianConstruct') ?? false;
    bool isTechnicianEarthworker = userPrefs.getBool('isTechnicianEarthworker') ?? false;

    List<String> teamNames = userPrefs.getStringList('teamNames') ?? [];
    List<String> roleNames = userPrefs.getStringList('roleNames') ?? [];

    print("👥 User Teams: $teamNames");
    print("🎭 User Roles: $roleNames");
    print("🔧 Technician Types - Autopsy: $isTechnicianAutopsy, Splicer: $isTechnicianSplicer, Construct: $isTechnicianConstruct, Earthworker: $isTechnicianEarthworker");

    // Log successful authentication
    String userInfo = "User authenticated successfully\n";
    userInfo += "Backend: ${BackendManager.getCurrentBackend().name.toUpperCase()}\n";
    if (_selectedTenant != null) {
      userInfo += "Tenant: $_selectedTenant\n";
    }
    userInfo += "Teams: ${teamNames.join(', ')}\n";
    userInfo += "Roles: ${roleNames.join(', ')}\n";
    
    if (isTechnicianAutopsy) userInfo += "✅ Autopsy technician access\n";
    if (isTechnicianSplicer) userInfo += "✅ Splicer technician access\n";
    if (isTechnicianConstruct) userInfo += "✅ Construction technician access\n";
    if (isTechnicianEarthworker) userInfo += "✅ Earthworker technician access\n";
    
    print("✅ $userInfo");
  }

  void _navigateToFetchDataScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const EnhancedFetchDataScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EnhancedSettingsScreen()),
    ).then((_) {
      // Reload settings when returning from settings screen
      _loadSavedSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _fadeAnimation != null && _slideAnimation != null 
          ? FadeTransition(
              opacity: _fadeAnimation!,
              child: SlideTransition(
                position: _slideAnimation!,
                child: _buildLoginContent(),
              ),
            )
          : _buildLoginContent(),
      ),
    );
  }

  Widget _buildLoginContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                   MediaQuery.of(context).padding.top - 
                   MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Settings Button
              Align(
                alignment: Alignment.topRight,
                child: _buildSettingsButton(),
              ),
              
              const SizedBox(height: 20),
              
              // Logo and Title
              _buildModernHeader(),
              
              const SizedBox(height: 40),
              
              // Backend and Tenant Selection
              _buildModernBackendSelector(),
              
              const SizedBox(height: 32),
              
              // Login Form
              _buildModernLoginForm(),
              
              const SizedBox(height: 24),
              
              // Login Button
              _buildModernLoginButton(),
              
              const SizedBox(height: 20),
              
              // Remember Me Checkbox
              _buildModernRememberMe(),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                _buildModernErrorMessage(),
              ],
              
              if (_backendStatus != null) ...[
                const SizedBox(height: 16),
                _buildModernStatusMessage(),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.settings_outlined, color: Color(0xFF0071BC)),
        onPressed: _openSettings,
        tooltip: 'Settings',
      ),
    );
  }

  Widget _buildModernHeader() {
    return Column(
      children: [
        // Logo Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0071BC),
                Color(0xFF005A94),
                Color(0xFF004A7C),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0071BC).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.business_center,
            size: 56,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        const Text(
          'FieldX FSM',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0071BC),
            letterSpacing: -0.5,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Field Service Management',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernBackendSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071BC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_outlined,
                  color: Color(0xFF0071BC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Backend Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Backend Selection
          DropdownButtonFormField<BackendType>(
            value: _selectedBackend,
            decoration: InputDecoration(
              labelText: 'Backend Type',
              prefixIcon: const Icon(Icons.dns_outlined, color: Color(0xFF0071BC)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0071BC), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: BackendType.values.map((backend) => DropdownMenuItem(
              value: backend,
              child: Text(
                backend.name.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            )).toList(),
            onChanged: isLoading ? null : (value) {
              setState(() {
                _selectedBackend = value!;
                if (value == BackendType.espocrm) {
                  _selectedTenant = null; // Clear tenant for EspoCRM
                }
              });
              _saveBackendSettings();
            },
          ),
          
          // Tenant Selection (only for Encore)
          if (_selectedBackend == BackendType.encore) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTenant,
              decoration: InputDecoration(
                labelText: 'Select Tenant',
                prefixIcon: const Icon(Icons.domain_outlined, color: Color(0xFF0071BC)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0071BC), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _availableTenants.map((tenant) => DropdownMenuItem(
                value: tenant['code'],
                child: Text(
                  '${tenant['name']} (${tenant['code']})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
              onChanged: isLoading ? null : (value) {
                setState(() {
                  _selectedTenant = value;
                });
                _saveBackendSettings();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Username Field
            TextFormField(
              controller: usernameController,
              enabled: !isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0071BC)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0071BC), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textInputAction: TextInputAction.next,
              autocorrect: false,
            ),
            
            const SizedBox(height: 20),
            
            // Password Field
            TextFormField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: isPasswordObscured,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0071BC)),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordObscured = !isPasswordObscured;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0071BC), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0071BC),
            Color(0xFF005A94),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0071BC).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _login,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: isLoading ? null : (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: const Color(0xFF0071BC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Remember me',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(),
        border: Border.all(color: _getStatusBorderColor()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusIconColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _backendStatus!,
                  style: TextStyle(
                    color: _getStatusTextColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_backendStatus!.contains('❌') || _backendStatus!.contains('⚠️')) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showTroubleshootingDialog,
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('Αντιμετώπιση προβλημάτων'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _testBackendConnection,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Επανάληψη'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0071BC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusBackgroundColor() {
    if (_backendStatus!.contains('✅')) return Colors.green[50]!;
    if (_backendStatus!.contains('⚠️')) return Colors.orange[50]!;
    if (_backendStatus!.contains('❌')) return Colors.red[50]!;
    return Colors.blue[50]!;
  }

  Color _getStatusBorderColor() {
    if (_backendStatus!.contains('✅')) return Colors.green[200]!;
    if (_backendStatus!.contains('⚠️')) return Colors.orange[200]!;
    if (_backendStatus!.contains('❌')) return Colors.red[200]!;
    return Colors.blue[200]!;
  }

  IconData _getStatusIcon() {
    if (_backendStatus!.contains('✅')) return Icons.check_circle_outline;
    if (_backendStatus!.contains('⚠️')) return Icons.warning_amber_outlined;
    if (_backendStatus!.contains('❌')) return Icons.error_outline;
    return Icons.info_outline;
  }

  Color _getStatusIconColor() {
    if (_backendStatus!.contains('✅')) return Colors.green[600]!;
    if (_backendStatus!.contains('⚠️')) return Colors.orange[600]!;
    if (_backendStatus!.contains('❌')) return Colors.red[600]!;
    return Colors.blue[600]!;
  }

  Color _getStatusTextColor() {
    if (_backendStatus!.contains('✅')) return Colors.green[700]!;
    if (_backendStatus!.contains('⚠️')) return Colors.orange[700]!;
    if (_backendStatus!.contains('❌')) return Colors.red[700]!;
    return Colors.blue[700]!;
  }

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.build_outlined, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Αντιμετώπιση προβλημάτων'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Πιθανές αιτίες του προβλήματος:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTroubleshootingItem('🔴', 'Ο Encore server δεν λειτουργεί'),
              _buildTroubleshootingItem('🔴', 'Πρόβλημα με το authentication service'),
              _buildTroubleshootingItem('🔴', 'Ο server χρειάζεται επανεκκίνηση'),
              _buildTroubleshootingItem('🔴', 'Λάθος διεύθυνση IP ή port'),
              _buildTroubleshootingItem('🔴', 'Λάθος ρυθμίσεις tenant'),
              _buildTroubleshootingItem('🔴', 'Firewall ή δικτυακό πρόβλημα'),
              const SizedBox(height: 16),
              const Text(
                'Λύσεις:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTroubleshootingItem('✅', 'Επανεκκινήστε τον Encore server'),
              _buildTroubleshootingItem('✅', 'Ελέγξτε αν ο server λειτουργεί'),  
              _buildTroubleshootingItem('✅', 'Επιβεβαιώστε τη διεύθυνση: 192.168.4.20:4002'),
              _buildTroubleshootingItem('✅', 'Ελέγξτε τις ρυθμίσεις tenant "beyond"'),
              _buildTroubleshootingItem('✅', 'Δοκιμάστε διαφορετικό tenant'),
              _buildTroubleshootingItem('✅', 'Επικοινωνήστε με τον διαχειριστή'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Κλείσιμο'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071BC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ρυθμίσεις'),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}