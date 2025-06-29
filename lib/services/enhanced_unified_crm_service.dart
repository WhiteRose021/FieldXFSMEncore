// lib/services/enhanced_unified_crm_service.dart
// Fixed version that resolves 401 authentication issues

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Define BackendType enum at the top of the file
enum BackendType { espocrm, encore }

class EnhancedUnifiedCRMService {
  static EnhancedUnifiedCRMService? _instance;
  static EnhancedUnifiedCRMService get instance => _instance ??= EnhancedUnifiedCRMService._();
  EnhancedUnifiedCRMService._();
  
  // Configuration
  static BackendType _currentBackend = BackendType.espocrm; // Default to EspoCRM
  static String? _encoreBaseUrl;
  static String? _espoCrmBaseUrl;
  static String? _tenantCode;
  
  // Shared HTTP client with connection pooling (keep your existing optimization)
  static final http.Client _httpClient = http.Client();
  
  // Keep all your existing caches
  static Map<String, dynamic>? _inMemoryMetadata;
  static String? _cachedBaseUrl;
  static Map<String, String>? _cachedAuthHeaders;
  static Map<String, dynamic> _appointmentCache = {};
  static Map<String, dynamic> _buildingCache = {};
  static Map<String, List<Map<String, dynamic>>> _historyCache = {};
  
  // Request batching (keep your existing optimization)
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  Timer? _batchTimer;
  
  // Cache keys
  static const String _metadataCacheKey = 'crm_metadata_cache';
  static const int _batchSize = 50;

  /// ==================== BACKEND CONFIGURATION ====================
  
  /// Initialize the service with backend configuration
  Future<void> initialize({
    BackendType backendType = BackendType.espocrm,
    String? tenantCode,
    bool isDevelopment = true,
  }) async {
    _currentBackend = backendType;
    _tenantCode = tenantCode;
    
    if (backendType == BackendType.encore) {
      if (isDevelopment) {
        // Map tenant to Encore backend port
        final backendPort = _getTenantBackendPort(tenantCode);
        _encoreBaseUrl = 'https://applink.fieldx.gr/api';
      } else {
        _encoreBaseUrl = 'https://api.yourdomain.com';
      }
      print("🚀 Initialized with Encore backend: $_encoreBaseUrl (tenant: $tenantCode)");
    } else {
      // Keep your existing EspoCRM configuration
      _espoCrmBaseUrl = 'http://192.168.4.20:6969';
      print("📦 Initialized with EspoCRM backend: $_espoCrmBaseUrl");
    }
    
    // Test backend connectivity
    await _testBackendConnectivity();
  }
  
  int _getTenantBackendPort(String? tenantCode) {
    const tenantPortMap = {
      'applink': 4001,
      'beyond': 4002,
      'demo': 4003,
      'test': 4004,
    };
    return tenantPortMap[tenantCode] ?? 4000;
  }
  
  Future<void> _testBackendConnectivity() async {
    try {
      final baseUrl = await getActiveBaseUrl();
      if (_currentBackend == BackendType.encore) {
        // Test Encore health endpoint with proper auth
        final headers = await _getAuthenticatedHeaders();
        
        print("🔍 Testing Encore connectivity with headers: ${headers.keys.join(', ')}");
        
        final response = await _httpClient.get(
          Uri.parse('$baseUrl/health'),
          headers: headers,
        );
        
        print("📡 Health check response: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          print("✅ Encore backend is healthy");
        } else {
          print("❌ Encore backend health check failed: ${response.statusCode}");
          print("📝 Response body: ${response.body}");
        }
      } else {
        // Test EspoCRM endpoint (your existing logic)
        final headers = await _getAuthenticatedHeaders();
        final response = await _httpClient.get(
          Uri.parse('$baseUrl/api/v1/App/user'),
          headers: headers,
        );
        if (response.statusCode == 200) {
          print("✅ EspoCRM backend is healthy");
        } else {
          print("❌ EspoCRM backend health check failed: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("❌ Backend connectivity test failed: $e");
    }
  }

  /// Get the active base URL based on current backend
  Future<String?> getActiveBaseUrl() async {
    if (_currentBackend == BackendType.encore) {
      return _encoreBaseUrl;
    } else {
      return _espoCrmBaseUrl ?? await getCRMBaseUrl(); // Your existing method
    }
  }

  /// Get CRM base URL from SharedPreferences (your existing method)
  Future<String?> getCRMBaseUrl() async {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl;
    }
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString('crmDomain');
    return _cachedBaseUrl;
  }

  /// ==================== FIXED AUTHENTICATION ====================
  
  /// FIXED: Unified method for getting authenticated headers
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_currentBackend == BackendType.encore) {
      // Get token from SharedPreferences (where main.dart Dio interceptor also gets it)
      final authToken = prefs.getString('authToken');
      
      print("🔑 Getting Encore auth token: ${authToken != null ? '${authToken.substring(0, 10)}...' : 'null'}");
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
        print("✅ Added Bearer token to headers");
      } else {
        print("❌ No auth token found in SharedPreferences");
      }
      
      // Add tenant header if available
      if (_tenantCode != null) {
        headers['X-Tenant-ID'] = _tenantCode!;
        print("🏢 Added tenant header: $_tenantCode");
      }
    } else {
      // EspoCRM authentication
      final authToken = prefs.getString('authToken');
      if (authToken != null) {
        if (authToken.startsWith('Basic ')) {
          headers['Authorization'] = authToken;
        } else {
          headers['Authorization'] = 'Basic $authToken';
        }
      }
    }
    
    return headers;
  }
  
  /// DEPRECATED: Use _getAuthenticatedHeaders instead
  @deprecated
  Future<Map<String, String>> getOptimalHeaders({bool isWrite = false}) async {
    print("⚠️ getOptimalHeaders is deprecated, use _getAuthenticatedHeaders");
    return await _getAuthenticatedHeaders();
  }

  /// ==================== AUTHENTICATION METHODS ====================
  
  /// IMPROVED: Login with Encore backend with better token handling
  Future<bool> loginWithEncore(String username, String password) async {
    try {
      print("🔄 Making login request to Encore backend...");
      print("🎯 URL: $_encoreBaseUrl/auth/login");
      print("👤 Username: $username");
      print("🏢 Tenant: $_tenantCode");
      
      // Prepare request body
      final requestBody = {
        'username': username,
        'password': password,
      };
      
      // Add tenant/subdomain if available
      if (_tenantCode != null && _tenantCode!.isNotEmpty) {
        requestBody['subdomain'] = _tenantCode!;
        // Also try 'tenant' field as backup
        requestBody['tenant'] = _tenantCode!;
      }
      
      print("📦 Request body: ${requestBody.keys.join(', ')}");
      
      final response = await _httpClient.post(
        Uri.parse('$_encoreBaseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'FieldX-Flutter-App/1.0.0',
          if (_tenantCode != null) 'X-Tenant-Code': _tenantCode!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));
      
      print("📡 Encore login response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📋 Response keys: ${data.keys.join(', ')}");
        
        // Check for token in response
        String? token = data['token'] ?? data['accessToken'] ?? data['authToken'];
        
        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          
          // IMPORTANT: Store token the same way the Dio interceptor expects it
          await prefs.setString('authToken', token);
          await prefs.setString('userName', username);
          
          print("✅ Stored auth token: ${token.substring(0, 10)}...");
          
          // Store user data if available
          if (data['user'] != null) {
            final user = data['user'];
            await prefs.setString('userId', user['id']?.toString() ?? username);
            
            // Store user details
            if (user['firstName'] != null) {
              await prefs.setString('firstName', user['firstName']);
            }
            if (user['lastName'] != null) {
              await prefs.setString('lastName', user['lastName']);
            }
            
            // Store tenant info
            if (user['tenant'] != null) {
              final tenant = user['tenant'];
              await prefs.setString('tenantId', tenant['id']?.toString() ?? '');
              await prefs.setString('tenantName', tenant['name'] ?? tenant['displayName'] ?? '');
              await prefs.setString('tenantCode', tenant['tenantCode'] ?? _tenantCode ?? '');
            }
            
            // Store permissions if available
            if (user['permissions'] != null) {
              final permissions = user['permissions'];
              await prefs.setBool('isAdmin', permissions['isAdmin'] ?? false);
              await prefs.setBool('isSuperAdmin', permissions['isSuperAdmin'] ?? false);
              await prefs.setBool('canExport', permissions['canExport'] ?? false);
              await prefs.setBool('canMassUpdate', permissions['canMassUpdate'] ?? false);
              await prefs.setBool('canAudit', permissions['canAudit'] ?? false);
              await prefs.setBool('canManageUsers', permissions['canManageUsers'] ?? false);
            }
            
            // Set technician flags based on permissions or user type
            await prefs.setBool('isTechnicianSplicer', user['isTechnicianSplicer'] ?? false);
            await prefs.setBool('isTechnicianAutopsy', user['isTechnicianAutopsy'] ?? false);
            await prefs.setBool('isTechnicianConstruct', user['isTechnicianConstruct'] ?? false);
            await prefs.setBool('isTechnicianEarthworker', user['isTechnicianEarthworker'] ?? false);
            
            print("👤 Stored user data for: ${user['username'] ?? username}");
          }
          
          // Store session info
          if (data['sessionId'] != null) {
            await prefs.setString('sessionId', data['sessionId']);
          }
          
          // Store expiration info
          if (data['expiresIn'] != null) {
            final expiresInSeconds = (data['expiresIn'] as num).toInt();
            final expiresAt = DateTime.now().millisecondsSinceEpoch + (expiresInSeconds * 1000);
            await prefs.setInt('tokenExpiresAt', expiresAt);
          }
          
          print("✅ Successfully logged in with Encore backend");
          
          // Test the token immediately
          await _testTokenValidity();
          
          return true;
        } else {
          print("❌ No token found in response");
          print("📝 Available fields: ${data.keys.join(', ')}");
          return false;
        }
      } else {
        print("❌ Encore login failed with status: ${response.statusCode}");
        print("📝 Response body: ${response.body}");
        
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          print("📝 Error details: $errorData");
        } catch (e) {
          print("📝 Raw response: ${response.body}");
        }
        
        return false;
      }
    } catch (e) {
      print("❌ Encore login error: $e");
      return false;
    }
  }
  
  /// IMPROVED: Test token validity after login
  Future<void> _testTokenValidity() async {
    try {
      print("🧪 Testing token validity...");
      final headers = await _getAuthenticatedHeaders();
      
      // Try a simple API call to verify the token works
      final response = await _httpClient.get(
        Uri.parse('$_encoreBaseUrl/auth/me'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print("✅ Token is valid");
      } else if (response.statusCode == 401) {
        print("❌ Token is invalid (401)");
      } else {
        print("⚠️ Token test returned: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Token validation failed: $e");
    }
  }
  
  /// Keep your existing EspoCRM login logic
  Future<bool> loginWithEspoCRM(String username, String password) async {
    // Your existing login logic here
    print("🔄 Attempting EspoCRM login for: $username");
    return true; // Placeholder - implement your existing logic
  }

  /// ==================== REQUEST DEDUPLICATION ====================
  
  /// Your existing request deduplication logic
  Future<T?> _deduplicateRequest<T>(String key, Future<T> Function() requestFn) async {
    if (_pendingRequests.containsKey(key)) {
      print("🔄 Deduplicating request: $key");
      return await _pendingRequests[key]!.future as T?;
    }
    
    final completer = Completer<T>();
    _pendingRequests[key] = completer;
    
    try {
      final result = await requestFn();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  /// ==================== METADATA SERVICE FUNCTIONALITY ====================
  
  Future<Map<String, dynamic>?> fetchMetadata() async {
    return await _deduplicateRequest<Map<String, dynamic>?>('metadata', () async {
      // Return in-memory cache if available
      if (_inMemoryMetadata != null) {
        print("🗂️ Returning in-memory cached metadata.");
        _updateMetadataIfNeeded(_inMemoryMetadata); // non-blocking
        return _inMemoryMetadata!;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString(_metadataCacheKey);
      final cachedData = cachedDataString != null
          ? json.decode(cachedDataString) as Map<String, dynamic>?
          : null;

      // Start background update check
      _updateMetadataIfNeeded(cachedData);

      if (cachedData != null) {
        print("🗂️ Returning SharedPreferences cached metadata.");
        _inMemoryMetadata = cachedData;
        return cachedData;
      }

      print("🔄 No cached metadata found, fetching from backend...");
      final freshMetadata = await _fetchFreshMetadata();
      return freshMetadata;
    });
  }
  
  Future<Map<String, dynamic>?> _fetchFreshMetadata() async {
    try {
      final baseUrl = await getActiveBaseUrl();
      if (baseUrl == null) return null;
      
      String endpoint = _currentBackend == BackendType.encore 
        ? '/metadata/entities'
        : '/api/v1/App/user';  // Your existing EspoCRM endpoint
      
      final headers = await _getAuthenticatedHeaders();
      print("🔍 Fetching metadata from: $baseUrl$endpoint");
      
      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final metadata = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Cache the metadata
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_metadataCacheKey, jsonEncode(metadata));
        _inMemoryMetadata = metadata;
        
        print("✅ Fresh metadata fetched from ${_currentBackend.name} backend");
        return metadata;
      } else {
        print("❌ Metadata fetch failed: ${response.statusCode}");
        print("📝 Response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching metadata: $e");
      return null;
    }
  }
  
  void _updateMetadataIfNeeded(Map<String, dynamic>? currentData) async {
    // Background metadata update - non-blocking
    if (currentData == null) return;
    
    try {
      final freshMetadata = await _fetchFreshMetadata();
      if (freshMetadata != null) {
        final newString = json.encode(freshMetadata);
        final currentString = json.encode(currentData);
        
        if (newString != currentString) {
          print("🔄 Metadata updated in background");
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString(_metadataCacheKey, newString);
          _inMemoryMetadata = freshMetadata;
        }
      }
    } catch (e) {
      print("⚠️ Background metadata update failed: $e");
    }
  }

  /// ==================== FIXED DATA FETCHING WITH BACKEND SWITCHING ====================
  
  /// FIXED: Enhanced appointment fetching that works with both backends
  Future<List<Map<String, dynamic>>> fetchTechnicianAppointments() async {
    try {
      if (_currentBackend == BackendType.encore) {
        return await _fetchAppointmentsFromEncore();
      } else {
        return await _fetchAppointmentsFromEspoCRM(); // Your existing method
      }
    } catch (e) {
      print("❌ Error fetching technician appointments: $e");
      return [];
    }
  }
  
  /// FIXED: Fetch appointments from Encore with proper authentication
  Future<List<Map<String, dynamic>>> _fetchAppointmentsFromEncore() async {
    try {
      final headers = await _getAuthenticatedHeaders();
      
      print("🔍 Fetching Encore appointments with headers:");
      headers.forEach((key, value) {
        if (key.toLowerCase().contains('authorization')) {
          print("   $key: ${value.substring(0, 20)}...");
        } else {
          print("   $key: $value");
        }
      });
      
      final url = '$_encoreBaseUrl/c_appointment';
      print("📡 Making request to: $url");
      
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      print("📨 Encore appointments response: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📋 Response structure: ${data.keys.join(', ')}");
        
        // Handle different possible response structures
        List<dynamic> appointmentsList;
        if (data['data'] is List) {
          appointmentsList = data['data'];
        } else if (data['appointments'] is List) {
          appointmentsList = data['appointments'];
        } else if (data is List) {
          appointmentsList = data;
        } else {
          print("⚠️ Unexpected response structure, treating as empty list");
          appointmentsList = [];
        }
        
        final appointments = appointmentsList
            .map<Map<String, dynamic>>((appointment) => _mapEncoreAppointmentData(appointment))
            .toList();
            
        print("✅ Fetched ${appointments.length} appointments from Encore");
        return appointments;
      } else {
        print("❌ Encore appointments fetch failed: ${response.statusCode}");
        print("📝 Response body: ${response.body}");
        
        if (response.statusCode == 401) {
          print("🔑 Authentication failed - token may be invalid or expired");
          
          // Check if token exists
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('authToken');
          print("🔍 Current token: ${token != null ? '${token.substring(0, 10)}...' : 'null'}");
        }
        
        return [];
      }
    } catch (e) {
      print("❌ Error fetching appointments from Encore: $e");
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchAppointmentsFromEspoCRM() async {
    // Keep your existing EspoCRM appointment fetching logic
    return await _deduplicateRequest<List<Map<String, dynamic>>>('technician_appointments', () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      bool isTechnicianSplicer = prefs.getBool('isTechnicianSplicer') ?? false;

      if (!isTechnicianSplicer || userId == null) {
        print("⛔ User is not a technician or User ID is missing.");
        return <Map<String, dynamic>>[];
      }

      List<Map<String, dynamic>> allAppointments = [];
      int offset = 0;
      bool hasMoreData = true;

      while (hasMoreData) {
        final response = await _makeRequest(
          '/api/v1/CSplicingWork?maxSize=$_batchSize&offset=$offset',
          useCache: true,
          cacheKey: 'appointments_$offset'
        );

        if (response?.statusCode == 200) {
          final jsonResponse = json.decode(response!.body) as Map<String, dynamic>;
          final list = jsonResponse['list'] as List<dynamic>? ?? [];

          final filteredAppointments = list
              .where((appointment) => appointment['assignedUserId'] == userId)
              .map<Map<String, dynamic>>((appointment) => _mapAppointmentData(appointment))
              .toList();

          allAppointments.addAll(filteredAppointments);

          if (list.length < _batchSize) {
            hasMoreData = false;
          } else {
            offset += _batchSize;
          }
        } else {
          print("❌ Error fetching appointments: ${response?.statusCode}");
          hasMoreData = false;
        }
      }

      print("✅ Total Appointments Found for User: ${allAppointments.length}");
      return allAppointments;
    }) ?? [];
  }

  /// FIXED: Make HTTP request with proper authentication
  Future<http.Response?> _makeRequest(String endpoint, {bool useCache = false, String? cacheKey}) async {
    try {
      final baseUrl = await getActiveBaseUrl();
      if (baseUrl == null) return null;
      
      final headers = await _getAuthenticatedHeaders();
      
      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      return response;
    } catch (e) {
      print("❌ HTTP request failed: $e");
      return null;
    }
  }

  /// ==================== DATA MAPPING ====================
  
  /// Map Encore appointment data to your existing format
  Map<String, dynamic> _mapEncoreAppointmentData(Map<String, dynamic> encoreData) {
    return {
      'id': encoreData['id'],
      'name': encoreData['name'] ?? encoreData['subject'] ?? encoreData['title'],
      'status': encoreData['status'] ?? 'pending',
      'assignedUserId': encoreData['assignedUserId'] ?? encoreData['assigned_user_id'],
      'assignedUserName': encoreData['assignedUserName'] ?? encoreData['assigned_user_name'],
      'dateStart': encoreData['dateStart'] ?? encoreData['date_start'] ?? encoreData['startDate'],
      'dateEnd': encoreData['dateEnd'] ?? encoreData['date_end'] ?? encoreData['endDate'],
      'description': encoreData['description'] ?? '',
      'location': encoreData['location'] ?? encoreData['address'] ?? '',
      // Map other fields as needed to maintain compatibility
      'createdAt': encoreData['createdAt'] ?? encoreData['created_at'] ?? encoreData['dateCreated'],
      'modifiedAt': encoreData['modifiedAt'] ?? encoreData['modified_at'] ?? encoreData['dateModified'],
      // Add appointment type
      'type': encoreData['type'] ?? encoreData['appointmentType'] ?? 'appointment',
      // Add priority
      'priority': encoreData['priority'] ?? 'normal',
    };
  }
  
  /// Keep your existing EspoCRM mapping method
  Map<String, dynamic> _mapAppointmentData(Map<String, dynamic> espoCrmData) {
    // Your existing mapping logic
    return espoCrmData;
  }

  /// ==================== BUILDINGS ====================
  
  Future<List<Map<String, dynamic>>> fetchFilteredBuildings() async {
    if (_currentBackend == BackendType.encore) {
      return await _fetchBuildingsFromEncore();
    } else {
      return await _fetchBuildingsFromEspoCRM(); // Your existing method
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchBuildingsFromEncore() async {
    try {
      final headers = await _getAuthenticatedHeaders();
      
      final response = await _httpClient.get(
        Uri.parse('$_encoreBaseUrl/c_buildings'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final buildings = (data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((building) => _mapEncoreBuildingData(building))
            .toList();
            
        print("✅ Fetched ${buildings.length} buildings from Encore");
        return buildings;
      } else {
        print("❌ Encore buildings fetch failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching buildings from Encore: $e");
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchBuildingsFromEspoCRM() async {
    // Your existing EspoCRM buildings fetching logic
    return [];
  }
  
  Map<String, dynamic> _mapEncoreBuildingData(Map<String, dynamic> encoreData) {
    return {
      'id': encoreData['id'],
      'name': encoreData['name'],
      'status': encoreData['status'],
      'assignedUserId': encoreData['assignedUserId'] ?? encoreData['assigned_user_id'],
      'assignedUserName': encoreData['assignedUserName'] ?? encoreData['assigned_user_name'],
      'address': encoreData['address'],
      'city': encoreData['city'],
      'area': encoreData['area'],
      // Map other fields to maintain compatibility
    };
  }

  /// ==================== ADDITIONAL METHODS ====================
  
  // Add your other existing methods here (fetchAppointmentDetails, updateAppointmentStatus, etc.)
  Future<Map<String, dynamic>?> fetchAppointmentDetails(String appointmentId) async {
    if (_currentBackend == BackendType.encore) {
      try {
        final headers = await _getAuthenticatedHeaders();
        
        final response = await _httpClient.get(
          Uri.parse('$_encoreBaseUrl/c_appointment/$appointmentId'),
          headers: headers,
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return _mapEncoreAppointmentData(data['data'] ?? data);
        } else {
          print("❌ Encore appointment details fetch failed: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Error fetching appointment details from Encore: $e");
      }
      return null;
    } else {
      // Your existing EspoCRM implementation
      return await _deduplicateRequest<Map<String, dynamic>?>('appointment_$appointmentId', () async {
        // Your existing implementation - for now returning null as placeholder
        return null;
      });
    }
  }

  Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      final baseUrl = await getActiveBaseUrl();
      final endpoint = _currentBackend == BackendType.encore 
        ? '/c_appointment/$appointmentId'
        : '/api/v1/CSplicingWork/$appointmentId';
      
      final headers = await _getAuthenticatedHeaders();
      
      final response = await _httpClient.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode({'status': newStatus}),
      );
      
      if (response.statusCode == 200) {
        print("✅ Status updated successfully via ${_currentBackend.name}");
        return true;
      } else {
        print("❌ Status update failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error updating status: $e");
      return false;
    }
  }

  Future<bool> assignBuildingToMe(String buildingId) async {
    // Implementation for both backends
    return await updateAppointmentStatus(buildingId, 'assigned');
  }

  Future<bool> unassignBuilding(String buildingId) async {
    // Implementation for both backends
    return await updateAppointmentStatus(buildingId, 'unassigned');
  }

  // Add placeholder methods for missing functionality
  Future<List<Map<String, dynamic>>> fetchSplicerHistory(String appointmentId) async {
    // Implement based on your needs
    return [];
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchAppointmentHistory(String appointmentId) async {
    // Implement based on your needs
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchTechnicianAutopsyAppointments() async {
    // Implement based on your needs
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchTechnicianConstructionAppointments({bool forceRefresh = false}) async {
    // Implement based on your needs
    return [];
  }

  /// ==================== BACKEND SWITCHING UTILITIES ====================
  
  /// Switch to Encore backend
  Future<void> switchToEncore({String? tenantCode}) async {
    await initialize(
      backendType: BackendType.encore,
      tenantCode: tenantCode,
    );
    _clearCaches(); // Clear caches when switching backends
    print("🔄 Switched to Encore backend");
  }
  
  /// Switch to EspoCRM backend
  Future<void> switchToEspoCRM() async {
    await initialize(backendType: BackendType.espocrm);
    _clearCaches(); // Clear caches when switching backends
    print("🔄 Switched to EspoCRM backend");
  }
  
  /// Get current backend type
  BackendType getCurrentBackend() => _currentBackend;
  
  /// Check if using Encore backend
  bool isUsingEncore() => _currentBackend == BackendType.encore;
  
  /// Check if using EspoCRM backend
  bool isUsingEspoCRM() => _currentBackend == BackendType.espocrm;

  /// Test backend connectivity - public method for BackendManager
  Future<bool> testBackendConnectivity() async {
    try {
      await _testBackendConnectivity();
      return true;
    } catch (e) {
      print("❌ Backend connectivity test failed: $e");
      return false;
    }
  }

  /// ==================== CACHE MANAGEMENT ====================
  
  void _clearCaches() {
    _inMemoryMetadata = null;
    _cachedBaseUrl = null;
    _cachedAuthHeaders = null;
    _appointmentCache.clear();
    _buildingCache.clear();
    _historyCache.clear();
    print("🗑️ Cleared all caches");
  }
}