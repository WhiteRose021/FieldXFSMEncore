// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authentication_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final AuthenticationService _authenticationService;
  bool _isAuthenticated = false;
  String? _currentUser;
  String? _authToken;

  AuthService({required AuthenticationService authenticationService})
      : _authenticationService = authenticationService;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;
  String? get authToken => _authToken;

  get currentUsername => null;

  Future<bool> authenticate(String username, String password) async {
  try {
    print("🔐 AuthenticationService.authenticate called for user: $username");
    
    // Get current backend type
    final prefs = await SharedPreferences.getInstance();
    final backendType = prefs.getString('selectedBackend') ?? 'espocrm';
    
    if (backendType == 'encore') {
      // Use Encore authentication
      final result = await _performEncoreAuthentication(username, password);
      return result['success'] == true;
    } else {
      // Use EspoCRM authentication
      final result = await _performEspoCRMAuthentication(username, password);
      return result['success'] == true;
    }
  } catch (e) {
    print("❌ Authentication failed: $e");
    return false;
  }
}

/// Encore authentication implementation
Future<Map<String, dynamic>> _performEncoreAuthentication(String username, String password) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final tenantCode = prefs.getString('selectedTenant');
    final isDevelopment = prefs.getBool('isDevelopment') ?? true;
    
    // Get the base URL for current backend
    String baseUrl;
    if (isDevelopment) {
      baseUrl = 'http://localhost:4000'; // Local Encore
    } else {
      baseUrl = 'https://production-encore-url.com'; // Production Encore
    }
    
    final body = {
      'username': username.trim(),
      'password': password,
    };
    
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
      await _storeAuthenticationData(data, 'encore');
      
      return {
        'success': true,
        'authToken': data['token'],
        'userName': data['user']['username'],
        'userId': data['user']['id'],
        'backend': 'encore'
      };
    } else {
      throw Exception('Authentication failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print("❌ Encore authentication error: $e");
    return {'success': false, 'error': e.toString()};
  }
}

/// EspoCRM authentication implementation
Future<Map<String, dynamic>> _performEspoCRMAuthentication(String username, String password) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final crmDomain = prefs.getString('crmDomain') ?? 'http://localhost:8080';
    
    // Basic authentication header
    final basicAuth = base64Encode(utf8.encode('$username:$password'));
    
    // Try to get current user info to validate credentials
    final response = await http.get(
      Uri.parse('$crmDomain/api/v1/App/user'),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      
      // Store authentication data
      await _storeAuthenticationData({
        'user': userData,
        'authToken': basicAuth,
      }, 'espocrm');
      
      return {
        'success': true,
        'authToken': basicAuth,
        'userName': userData['userName'] ?? username,
        'userId': userData['id'],
        'backend': 'espocrm'
      };
    } else {
      throw Exception('EspoCRM authentication failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print("❌ EspoCRM authentication error: $e");
    return {'success': false, 'error': e.toString()};
  }
}

/// Store authentication data to SharedPreferences
Future<void> _storeAuthenticationData(Map<String, dynamic> authData, String backend) async {
  final prefs = await SharedPreferences.getInstance();
  
  try {
    if (backend == 'encore') {
      final user = authData['user'];
      await prefs.setString('authToken', authData['token'] ?? '');
      await prefs.setString('userName', user['username'] ?? '');
      await prefs.setString('userId', user['id'] ?? '');
      await prefs.setString('userType', user['type'] ?? 'regular');
      await prefs.setString('tenantName', user['tenantName'] ?? '');
    } else if (backend == 'espocrm') {
      final user = authData['user'];
      await prefs.setString('authToken', authData['authToken'] ?? '');
      await prefs.setString('userName', user['userName'] ?? '');
      await prefs.setString('userId', user['id'] ?? '');
      await prefs.setString('userType', user['type'] ?? 'regular');
    }
    
    await prefs.setString('backend', backend);
    print("✅ Authentication data stored successfully for $backend backend");
  } catch (e) {
    print("⚠️ Failed to store authentication data: $e");
  }
}


  /// Login with credentials
  Future<bool> login(String username, String password) async {
    return await authenticate(username, password);
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Clear authentication state
      _isAuthenticated = false;
      _currentUser = null;
      _authToken = null;
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userName');
      await prefs.remove('userId');
      await prefs.remove('crmDomain');
      
      notifyListeners();
      
      debugPrint('User logged out successfully');
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
      
      if (authToken != null && authToken.isNotEmpty &&
          userName != null && userName.isNotEmpty) {
        _isAuthenticated = true;
        _currentUser = userName;
        _authToken = authToken;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (error) {
      debugPrint('Auth check error: $error');
      return false;
    }
  }

  /// Initialize auth service
  Future<void> initialize() async {
    await checkAuthentication();
  }

  /// Refresh authentication token if needed
  Future<void> refreshToken() async {
    // Implementation depends on your backend authentication system
    // This is a placeholder for token refresh logic
    if (_isAuthenticated && _authToken != null) {
      try {
        // Call your token refresh endpoint here
        debugPrint('Token refresh not implemented yet');
      } catch (error) {
        debugPrint('Token refresh error: $error');
        // If refresh fails, logout user
        await logout();
      }
    }
  }

  /// Get current user information
  Future<Map<String, String?>> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'authToken': prefs.getString('authToken'),
      'userName': prefs.getString('userName'),
      'userId': prefs.getString('userId'),
      'crmDomain': prefs.getString('crmDomain'),
    };
  }
}