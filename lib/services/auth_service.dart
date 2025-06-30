// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';
import 'backend_service.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUser;
  String? _authToken;
  String? _userId;
  String? _userType;
  String? _tenantName;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;
  String? get authToken => _authToken;
  String? get userId => _userId;
  String? get userType => _userType;
  String? get tenantName => _tenantName;

  /// 🔥 NEW: Refresh the API configuration (call this after environment changes)
  Future<void> refreshConfiguration() async {
    try {
      // Get the updated API URL from BackendConfig
      final newApiUrl = await BackendConfig.getApiBaseUrl();
      final environment = await BackendConfig.getEnvironment();
      final tenant = await BackendConfig.getTenant();
      
      debugPrint('🔄 AuthService: Configuration refreshed');
      debugPrint('🌍 Environment: $environment');
      debugPrint('🔗 API URL: $newApiUrl');
      debugPrint('🏢 Tenant: ${tenant.isEmpty ? "None" : tenant}');
      
      // 🔥 KEY FIX: Refresh BackendService configuration
      await BackendService.instance.refreshConfiguration();
      
      // If user has auth token, set it in BackendService again
      if (_authToken != null && _authToken!.isNotEmpty) {
        BackendService.instance.setAuthToken(_authToken!);
      }
      
      // Clear any cached data that might be environment-specific
      _clearCachedData();
      
      // Notify listeners so UI can update
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ AuthService: Error refreshing configuration: $e');
    }
  }

  /// Clear cached authentication data when environment changes
  void _clearCachedData() {
    // If user was authenticated but environment changed, they need to re-login
    if (_isAuthenticated) {
      debugPrint('🔄 Environment changed, user will need to re-authenticate');
      // Note: We don't auto-logout here, just clear cache
      // User can try to login with new environment
    }
  }

  /// Get the API base URL using BackendConfig
  Future<String> _getApiBaseUrl() async {
    return await BackendConfig.getApiBaseUrl();
  }

  /// Authenticate with Encore backend
  Future<bool> authenticate(String username, String password) async {
    try {
      final baseUrl = await _getApiBaseUrl();
      final tenant = await BackendConfig.getTenant();
      
      debugPrint('🔐 Attempting authentication...');
      debugPrint('🔗 Using API URL: $baseUrl');
      debugPrint('🏢 Tenant: ${tenant.isEmpty ? "None" : tenant}');
      
      final body = {
        'username': username.trim(),
        'password': password,
      };
      
      // Add tenant/subdomain if configured
      if (tenant.isNotEmpty) {
        body['subdomain'] = tenant;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('🔐 Auth response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store authentication data
        await _storeAuthenticationData(data);
        
        debugPrint('✅ Authentication successful');
        return true;
      } else {
        debugPrint('❌ Authentication failed with status: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Authentication error: $e');
      return false;
    }
  }

  /// Store authentication data from Encore response
  Future<void> _storeAuthenticationData(Map<String, dynamic> authData) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final user = authData['user'] ?? {};
      final token = authData['token'] ?? '';
      
      // Store in SharedPreferences
      await prefs.setString('authToken', token);
      await prefs.setString('userName', user['username'] ?? '');
      await prefs.setString('userId', user['id'] ?? '');
      await prefs.setString('userType', user['type'] ?? 'regular');
      await prefs.setString('tenantName', user['tenantName'] ?? '');
      
      // Update local state
      _authToken = token;
      _currentUser = user['username'] ?? '';
      _userId = user['id'] ?? '';
      _userType = user['type'] ?? 'regular';
      _tenantName = user['tenantName'] ?? '';
      _isAuthenticated = true;
      
      // 🔥 KEY FIX: Set auth token in BackendService for AutopsyService to use
      BackendService.instance.setAuthToken(token);
      
      notifyListeners();
      
      debugPrint('✅ Authentication data stored successfully');
      debugPrint('👤 User: $_currentUser');
      debugPrint('🏷️ Type: $_userType');
      debugPrint('🔑 Auth token set in BackendService');
    } catch (e) {
      debugPrint('❌ Error storing authentication data: $e');
    }
  }

  /// Login with credentials (alias for authenticate)
  Future<bool> login(String username, String password) async {
    return await authenticate(username, password);
  }

  /// Logout user and clear all data
  Future<void> logout() async {
    try {
      // Clear authentication state
      _isAuthenticated = false;
      _currentUser = null;
      _authToken = null;
      _userId = null;
      _userType = null;
      _tenantName = null;
      
      // 🔥 KEY FIX: Clear auth token from BackendService
      BackendService.instance.clearAuthToken();
      
      // Clear shared preferences (only auth-related data)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userName');
      await prefs.remove('userId');
      await prefs.remove('userType');
      await prefs.remove('tenantName');
      
      // Note: We keep environment and tenant settings for next login
      
      notifyListeners();
      
      debugPrint('✅ User logged out successfully');
      debugPrint('🔑 Auth token cleared from BackendService');
    } catch (error) {
      debugPrint('❌ Logout error: $error');
      rethrow;
    }
  }

  /// Check if user is authenticated by checking stored credentials
  Future<bool> checkAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');
      final userName = prefs.getString('userName');
      final userId = prefs.getString('userId');
      
      if (authToken != null && authToken.isNotEmpty &&
          userName != null && userName.isNotEmpty &&
          userId != null && userId.isNotEmpty) {
        
        // Load stored authentication data
        _authToken = authToken;
        _currentUser = userName;
        _userId = userId;
        _userType = prefs.getString('userType') ?? 'regular';
        _tenantName = prefs.getString('tenantName') ?? '';
        _isAuthenticated = true;
        
        // 🔥 KEY FIX: Set auth token in BackendService for existing authentication
        BackendService.instance.setAuthToken(authToken);
        
        debugPrint('✅ Found existing authentication');
        debugPrint('👤 User: $_currentUser');
        debugPrint('🔑 Auth token restored in BackendService');
        
        notifyListeners();
        return true;
      }
      
      debugPrint('ℹ️ No existing authentication found');
      return false;
    } catch (error) {
      debugPrint('❌ Auth check error: $error');
      return false;
    }
  }

  /// Initialize auth service - check if already authenticated
  Future<void> initialize() async {
    debugPrint('🚀 Initializing AuthService...');
    await checkAuthentication();
  }

  /// Refresh authentication token if needed
  Future<void> refreshToken() async {
    if (!_isAuthenticated || _authToken == null) return;
    
    try {
      final baseUrl = await _getApiBaseUrl();
      
      debugPrint('🔄 Refreshing auth token...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storeAuthenticationData(data);
        debugPrint('✅ Token refreshed successfully');
      } else {
        debugPrint('❌ Token refresh failed, logging out user');
        await logout();
      }
    } catch (error) {
      debugPrint('❌ Token refresh error: $error');
      // If refresh fails, logout user
      await logout();
    }
  }

  /// Get current user information
  Future<Map<String, String?>> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'authToken': prefs.getString('authToken'),
      'userName': prefs.getString('userName'),
      'userId': prefs.getString('userId'),
      'userType': prefs.getString('userType'),
      'tenantName': prefs.getString('tenantName'),
    };
  }

  /// DEPRECATED: Use BackendConfig.configureDevelopment() instead
  @deprecated
  Future<void> setEnvironment(bool isDevelopment) async {
    debugPrint('⚠️ setEnvironment is deprecated, use BackendConfig instead');
    
    if (isDevelopment) {
      await BackendConfig.configureDevelopment();
    } else {
      await BackendConfig.configureProduction();
    }
    
    // Refresh configuration after change
    await refreshConfiguration();
  }

  /// DEPRECATED: Use BackendConfig.setTenant() instead
  @deprecated
  Future<void> setTenant(String tenantCode) async {
    debugPrint('⚠️ setTenant is deprecated, use BackendConfig instead');
    
    await BackendConfig.setTenant(tenantCode);
    
    // Refresh configuration after change
    await refreshConfiguration();
  }

  /// Get current environment setting
  Future<bool> isDevelopmentMode() async {
    return await BackendConfig.isDevelopment();
  }

  /// Get current tenant setting
  Future<String?> getCurrentTenant() async {
    return await BackendConfig.getTenant();
  }

  /// Get auth headers for API requests
  Map<String, String> getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  /// Check if current auth token is valid (simple check)
  bool hasValidToken() {
    return _isAuthenticated && 
           _authToken != null && 
           _authToken!.isNotEmpty;
  }
}