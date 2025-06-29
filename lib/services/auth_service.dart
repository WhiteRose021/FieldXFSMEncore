// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  /// Get the API base URL based on environment
  Future<String> _getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final isDevelopment = prefs.getBool('isDevelopment') ?? true;
    
    if (isDevelopment) {
      return 'http://localhost:4000'; // Local Encore development
    } else {
      return 'https://applink.fieldx.gr/api'; // Production Encore
    }
  }

  /// Authenticate with Encore backend
  Future<bool> authenticate(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = await _getApiBaseUrl();
      final tenantCode = prefs.getString('selectedTenant');
      
      final body = {
        'username': username.trim(),
        'password': password,
      };
      
      // Add tenant/subdomain if configured
      if (tenantCode != null && tenantCode.isNotEmpty) {
        body['subdomain'] = tenantCode;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store authentication data
        await _storeAuthenticationData(data);
        
        return true;
      } else {
        debugPrint('Authentication failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
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
      
      notifyListeners();
      
      debugPrint('✅ Authentication data stored successfully');
    } catch (e) {
      debugPrint('Error storing authentication data: $e');
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
      
      // Clear shared preferences (only auth-related data)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userName');
      await prefs.remove('userId');
      await prefs.remove('userType');
      await prefs.remove('tenantName');
      
      // Note: We keep selectedTenant and isDevelopment for next login
      
      notifyListeners();
      
      debugPrint('✅ User logged out successfully');
    } catch (error) {
      debugPrint('Logout error: $error');
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
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (error) {
      debugPrint('Auth check error: $error');
      return false;
    }
  }

  /// Initialize auth service - check if already authenticated
  Future<void> initialize() async {
    await checkAuthentication();
  }

  /// Refresh authentication token if needed
  Future<void> refreshToken() async {
    if (!_isAuthenticated || _authToken == null) return;
    
    try {
      final baseUrl = await _getApiBaseUrl();
      
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
        debugPrint('Token refresh failed, logging out user');
        await logout();
      }
    } catch (error) {
      debugPrint('Token refresh error: $error');
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

  /// Set environment (development/production)
  Future<void> setEnvironment(bool isDevelopment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDevelopment', isDevelopment);
    
    // If user is authenticated, they'll need to re-login for the new environment
    if (_isAuthenticated) {
      debugPrint('Environment changed, logout required');
      await logout();
    }
  }

  /// Set tenant for multi-tenant setups
  Future<void> setTenant(String tenantCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTenant', tenantCode);
    
    // If user is authenticated, they'll need to re-login for the new tenant
    if (_isAuthenticated) {
      debugPrint('Tenant changed, logout required');
      await logout();
    }
  }

  /// Get current environment setting
  Future<bool> isDevelopmentMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDevelopment') ?? true;
  }

  /// Get current tenant setting
  Future<String?> getCurrentTenant() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedTenant');
  }
}