// lib/services/enhanced_authentication_service.dart
// Extension to your existing AuthenticationService to handle Encore backend better

import 'dart:convert';
import 'package:fieldx_fsm/services/enhanced_unified_crm_service.dart' show EnhancedUnifiedCRMService;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'enhanced_service_adapters.dart';

class EnhancedAuthenticationHelper {
  
  /// Store enhanced user data from Encore login response
  static Future<void> storeEncoreUserData(Map<String, dynamic> loginResponse) async {
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
      await prefs.setString('encore_auth_token', loginResponse['token'] ?? '');
      
      // Calculate and store expiration time
      final expiresIn = loginResponse['expiresIn'] as int? ?? 3600;
      final expirationTime = DateTime.now().add(Duration(seconds: expiresIn));
      await prefs.setString('tokenExpiresAt', expirationTime.toIso8601String());
      
      // Store tenant information
      if (tenant != null) {
        await prefs.setString('tenantId', tenant['id'] ?? '');
        await prefs.setString('tenantName', tenant['name'] ?? tenant['displayName'] ?? '');
        await prefs.setString('tenantCode', tenant['tenantCode'] ?? '');
        await prefs.setString('tenantStatus', tenant['status'] ?? 'ACTIVE');
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
      
      // Log the stored data
      print("💾 Enhanced user data stored:");
      print("   - User ID: ${user['id']}");
      print("   - Username: ${user['username']}");
      print("   - Type: ${user['type']}");
      print("   - Tenant: ${user['tenantName']}");
      print("   - Is Admin: ${permissions?['isAdmin']}");
      print("   - Is Super Admin: ${permissions?['isSuperAdmin']}");
      print("   - Token expires in: $expiresIn seconds");
      
    } catch (e) {
      print("❌ Error storing enhanced user data: $e");
      rethrow;
    }
  }

  /// Validate current session with Encore backend
  static Future<bool> validateEncoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('encore_auth_token');
      final expiresAtStr = prefs.getString('tokenExpiresAt');
      
      if (token == null || expiresAtStr == null) {
        print("❌ No Encore session found");
        return false;
      }

      // Check if token is expired locally first
      final expiresAt = DateTime.parse(expiresAtStr);
      if (DateTime.now().isAfter(expiresAt)) {
        print("❌ Encore token expired locally");
        await clearEncoreSession();
        return false;
      }

      // Get current backend config to determine the URL
      final enhancedService = EnhancedUnifiedCRMService.instance;
      final baseUrl = await enhancedService.getActiveBaseUrl();
      
      if (baseUrl == null) {
        print("❌ No active base URL for session validation");
        return false;
      }

      // Verify with Encore backend
      final url = Uri.parse('$baseUrl/auth/check-session');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print("📨 Encore session check response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isValid = data['valid'] ?? false;
        
        if (isValid) {
          print("✅ Encore session is valid");
          return true;
        } else {
          print("❌ Encore session is invalid");
          await clearEncoreSession();
          return false;
        }
      } else {
        print("❌ Encore session check failed with status: ${response.statusCode}");
        await clearEncoreSession();
        return false;
      }
    } catch (e) {
      print("❌ Encore session validation error: $e");
      return false;
    }
  }

  /// Clear Encore-specific session data
  static Future<void> clearEncoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.remove('encore_auth_token'),
      prefs.remove('sessionId'),
      prefs.remove('tokenExpiresAt'),
      prefs.remove('tenantId'),
      prefs.remove('tenantName'),
      prefs.remove('tenantCode'),
      prefs.remove('tenantStatus'),
      prefs.remove('isAdmin'),
      prefs.remove('isSuperAdmin'),
      prefs.remove('canExport'),
      prefs.remove('canMassUpdate'),
      prefs.remove('canAudit'),
      prefs.remove('canManageUsers'),
    ]);
    
    print("🧹 Encore session data cleared");
  }

  /// Perform Encore login
  static Future<Map<String, dynamic>> performEncoreLogin(String username, String password) async {
    try {
      // Get current backend config
      final enhancedService = EnhancedUnifiedCRMService.instance;
      final baseUrl = await enhancedService.getActiveBaseUrl();
      
      if (baseUrl == null) {
        throw Exception("No Encore backend URL configured");
      }

      final url = Uri.parse('$baseUrl/auth/login');
      final body = {
        'username': username,
        'password': password,
      };

      print("📡 Making Encore login request to: $url");
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      print("📨 Encore login response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Store the enhanced user data
        await storeEncoreUserData(data);
        
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Login failed';
        print("❌ Encore login failed: $errorMessage");
        throw Exception(errorMessage);
      }
    } catch (e) {
      print("❌ Encore login error: $e");
      rethrow;
    }
  }

  /// Get user roles and teams from stored data or fetch from backend
  static Future<Map<String, List<String>>> getUserRolesAndTeams() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get from stored data first
    final storedTeams = prefs.getStringList('teamNames') ?? [];
    final storedRoles = prefs.getStringList('roleNames') ?? [];
    
    if (storedTeams.isNotEmpty || storedRoles.isNotEmpty) {
      return {
        'teams': storedTeams,
        'roles': storedRoles,
      };
    }

    // If no stored data, try to fetch from backend
    try {
      final enhancedService = EnhancedUnifiedCRMService.instance;
      final baseUrl = await enhancedService.getActiveBaseUrl();
      final token = prefs.getString('encore_auth_token');
      
      if (baseUrl != null && token != null) {
        final url = Uri.parse('$baseUrl/auth/user-roles-teams');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final roles = (data['roles'] as List?)?.map((r) => r['name'] as String).toList() ?? [];
          final teams = (data['teams'] as List?)?.map((t) => t['name'] as String).toList() ?? [];
          
          // Store for future use
          await prefs.setStringList('roleNames', roles);
          await prefs.setStringList('teamNames', teams);
          
          return {
            'teams': teams,
            'roles': roles,
          };
        }
      }
    } catch (e) {
      print("⚠️ Failed to fetch roles and teams: $e");
    }

    return {
      'teams': <String>[],
      'roles': <String>[],
    };
  }

  /// Check if user has specific permission
  static Future<bool> hasPermission(String permission) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (permission.toLowerCase()) {
      case 'admin':
        return prefs.getBool('isAdmin') ?? false;
      case 'superadmin':
      case 'super_admin':
        return prefs.getBool('isSuperAdmin') ?? false;
      case 'export':
        return prefs.getBool('canExport') ?? false;
      case 'mass_update':
        return prefs.getBool('canMassUpdate') ?? false;
      case 'audit':
        return prefs.getBool('canAudit') ?? false;
      case 'manage_users':
        return prefs.getBool('canManageUsers') ?? false;
      default:
        return false;
    }
  }

  /// Get current user display name
  static Future<String> getUserDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';
    final username = prefs.getString('userName') ?? '';
    
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    
    return username;
  }

  /// Print comprehensive user information
  static Future<void> printUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final rolesAndTeams = await getUserRolesAndTeams();
    
    print("👤 USER INFORMATION:");
    print("   - ID: ${prefs.getString('userId')}");
    print("   - Username: ${prefs.getString('userName')}");
    print("   - Display Name: ${await getUserDisplayName()}");
    print("   - Type: ${prefs.getString('userType')}");
    print("   - Tenant: ${prefs.getString('tenantName')} (${prefs.getString('tenantCode')})");
    print("   - Backend: ${BackendManager.getCurrentBackend().name}");
    
    print("🔐 PERMISSIONS:");
    print("   - Admin: ${prefs.getBool('isAdmin')}");
    print("   - Super Admin: ${prefs.getBool('isSuperAdmin')}");
    print("   - Export: ${prefs.getBool('canExport')}");
    print("   - Mass Update: ${prefs.getBool('canMassUpdate')}");
    print("   - Audit: ${prefs.getBool('canAudit')}");
    print("   - Manage Users: ${prefs.getBool('canManageUsers')}");
    
    print("🎭 ROLES: ${rolesAndTeams['roles']?.join(', ') ?? 'None'}");
    print("👥 TEAMS: ${rolesAndTeams['teams']?.join(', ') ?? 'None'}");
  }
}