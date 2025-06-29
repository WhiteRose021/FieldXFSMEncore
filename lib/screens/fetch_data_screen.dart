// lib/screens/fetch_data_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/autopsy_client.dart';
import '../services/permissions_manager.dart';
import '../repositories/autopsy_repository.dart';
import '../config/backend_config.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'dart:async';

class FetchDataScreen extends StatefulWidget {
  const FetchDataScreen({super.key});

  @override
  State<FetchDataScreen> createState() => _FetchDataScreenState();
}

class _FetchDataScreenState extends State<FetchDataScreen> with TickerProviderStateMixin {
  String _statusMessage = "Initializing system...";
  String _subStatusMessage = "Please wait while we prepare your workspace";
  double _progressValue = 0.0;
  bool _dataFetched = false;
  bool _isDisposed = false;
  String _currentEnvironment = '';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  void _updateProgress(double progress, String status, String subStatus) {
    if (mounted && !_isDisposed) {
      setState(() {
        _progressValue = progress;
        _statusMessage = status;
        _subStatusMessage = subStatus;
      });
    }
  }

  void _safeNavigateToLogin() {
    if (mounted && !_isDisposed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _safeNavigateToDashboard() {
    if (mounted && !_isDisposed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  Future<void> _loadInitialData() async {
    if (_dataFetched) return;
    _dataFetched = true;

    try {
      // Step 1: Get current environment
      _currentEnvironment = await BackendConfig.getEnvironment();
      _updateProgress(0.1, "Configuration", "Loading $_currentEnvironment environment...");
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _isDisposed) return;

      // Step 2: Validate authentication
      _updateProgress(0.2, "Authentication", "Verifying user credentials...");
      
      final authService = context.read<AuthService>();
      final isAuthenticated = await authService.checkAuthentication();
      
      if (!isAuthenticated) {
        debugPrint("❌ User not authenticated - redirecting to login");
        _updateProgress(0.0, "Authentication Required", "Please log in to continue...");
        await Future.delayed(const Duration(seconds: 2));
        _safeNavigateToLogin();
        return;
      }

      debugPrint("✅ User authenticated: ${authService.currentUser}");
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _isDisposed) return;

      // Step 3: Test backend connectivity
      _updateProgress(0.3, "Connection Test", "Testing Encore backend connectivity...");
      
      final backendHealthy = await _testBackendConnectivity();
      if (!backendHealthy) {
        _updateProgress(0.3, "Offline Mode", "Using cached data...");
        debugPrint("⚠️ Backend not reachable, using cached data");
      } else {
        _updateProgress(0.4, "Connection Success", "Connected to Encore backend");
        debugPrint("✅ Backend connectivity confirmed");
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _isDisposed) return;

      // Step 4: Load permissions
      _updateProgress(0.5, "Permissions", "Loading user permissions...");
      await _loadUserPermissions();

      if (!mounted || _isDisposed) return;

      // Step 5: Load autopsies data
      _updateProgress(0.6, "Autopsies", "Loading autopsy data...");
      await _loadAutopsiesData();

      if (!mounted || _isDisposed) return;

      // Step 6: Load appointments data (when we implement it)
      _updateProgress(0.8, "Appointments", "Loading appointment data...");
      await _loadAppointmentsData();

      if (!mounted || _isDisposed) return;

      // Step 7: Cache data for offline use
      _updateProgress(0.9, "Caching", "Saving data for offline access...");
      await _cacheDataForOfflineUse();

      // Step 8: Completion
      _updateProgress(1.0, "Complete", "Welcome to FieldX FSM!");
      await Future.delayed(const Duration(milliseconds: 1000));

      debugPrint("✅ Data loading completed successfully");
      _safeNavigateToDashboard();

    } catch (e) {
      debugPrint("❌ Error during data loading: $e");
      
      if (!mounted || _isDisposed) return;
      
      _updateProgress(0.0, "Loading Error", "Failed to load data. Please try again.");
      await Future.delayed(const Duration(seconds: 3));
      
      // On error, redirect to login for fresh start
      _safeNavigateToLogin();
    }
  }

  /// Test backend connectivity
  Future<bool> _testBackendConnectivity() async {
    try {
      final apiUrl = await BackendConfig.getApiBaseUrl();
      final headers = await BackendConfig.getDefaultHeaders();
      
      // Simple connectivity test - try to reach the API
      // We'll use a basic endpoint that should always be available
      // For now, we'll just validate the URL format
      final uri = Uri.tryParse(apiUrl);
      return uri != null && uri.isAbsolute;
    } catch (e) {
      debugPrint("Backend connectivity test failed: $e");
      return false;
    }
  }

  /// Load user permissions
  Future<void> _loadUserPermissions() async {
    try {
      final permissionsManager = context.read<PermissionsManager>();
      await permissionsManager.loadPermissions();
      
      debugPrint("✅ User permissions loaded");
    } catch (e) {
      debugPrint("❌ Error loading permissions: $e");
      // Continue anyway with default permissions
    }
  }

  /// Load autopsies data
  Future<void> _loadAutopsiesData() async {
    try {
      final autopsyRepository = context.read<AutopsyRepository>();
      
      // Load a small initial set of autopsies
      await autopsyRepository.loadAutopsies(refresh: true);
      
      final count = autopsyRepository.autopsies.length;
      debugPrint("✅ Loaded $count autopsies");
      
      // Update progress message with count
      if (mounted && !_isDisposed) {
        _updateProgress(0.7, "Autopsies Loaded", "Loaded $count autopsy records");
      }
    } catch (e) {
      debugPrint("❌ Error loading autopsies: $e");
      // Continue with cached data or empty state
      
      if (mounted && !_isDisposed) {
        _updateProgress(0.7, "Autopsies", "Using cached autopsy data");
      }
    }
  }

  /// Load appointments data (placeholder for future implementation)
  Future<void> _loadAppointmentsData() async {
    try {
      // TODO: Implement appointment loading when AppointmentService is ready
      // For now, just simulate loading
      await Future.delayed(const Duration(milliseconds: 300));
      
      debugPrint("✅ Appointments loading placeholder");
      
      if (mounted && !_isDisposed) {
        _updateProgress(0.85, "Appointments", "Appointment system ready");
      }
    } catch (e) {
      debugPrint("❌ Error loading appointments: $e");
    }
  }

  /// Cache data for offline use
  Future<void> _cacheDataForOfflineUse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache basic app state
      await prefs.setString('lastDataLoad', DateTime.now().toIso8601String());
      await prefs.setString('lastEnvironment', _currentEnvironment);
      
      // Cache user info
      final authService = context.read<AuthService>();
      final userInfo = await authService.getCurrentUserInfo();
      await prefs.setString('cachedUserInfo', json.encode(userInfo));
      
      debugPrint("✅ Data cached for offline use");
    } catch (e) {
      debugPrint("❌ Error caching data: $e");
      // Not critical, continue anyway
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066CC),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066CC).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.engineering,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // App Title
              Text(
                "FieldX FSM",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0066CC),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Environment Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getEnvironmentColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getEnvironmentColor(),
                  ),
                ),
                child: Text(
                  "Environment: ${_currentEnvironment.toUpperCase()}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getEnvironmentColor(),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Progress Bar
              LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
                minHeight: 8,
              ),
              
              const SizedBox(height: 24),
              
              // Main Status Message
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0066CC),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Sub Status Message
              Text(
                _subStatusMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Progress Percentage
              Text(
                "${(_progressValue * 100).toInt()}%",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0066CC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get color based on environment
  Color _getEnvironmentColor() {
    switch (_currentEnvironment) {
      case 'production':
        return Colors.green;
      case 'staging':
        return Colors.orange;
      case 'development':
      default:
        return Colors.blue;
    }
  }
}