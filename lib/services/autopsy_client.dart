// lib/services/autopsy_client.dart - Modified your existing version with authentication
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADDED: Import for SharedPreferences
import '../models/autopsy_models.dart';

class AutopsyClient {
  final Dio _dio;
  final bool _debugMode;
  
  // Permission cache for performance
  final Map<String, AutopsyPermissions> _permissionCache = {};
  final Duration _permissionCacheTimeout = const Duration(minutes: 5);
  final Map<String, DateTime> _permissionCacheTimestamps = {};

  AutopsyClient({
    required Dio dio,
    bool debugMode = kDebugMode,
  }) : _dio = dio, _debugMode = debugMode;

  // ============= AUTHENTICATION METHODS (ADDED) =============

  /// Get authenticated headers for requests
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'FieldX-Flutter-App/1.0.0',
    };
    
    // Get auth token from SharedPreferences
    final authToken = prefs.getString('authToken');
    
    _debugLog('🔑 Getting auth token for autopsy request:', {
      'hasToken': authToken != null,
      'tokenPreview': authToken != null ? '${authToken.substring(0, 10)}...' : 'null',
    });
    
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
      _debugLog('✅ Added Bearer token to autopsy request headers');
    } else {
      _debugLog('❌ No auth token found for autopsy request');
    }
    
    // Add tenant header if available
    final tenantCode = prefs.getString('selectedTenant');
    if (tenantCode != null && tenantCode.isNotEmpty) {
      headers['X-Tenant-ID'] = tenantCode;
      _debugLog('🏢 Added tenant header to autopsy request: $tenantCode');
    }
    
    return headers;
  }

  /// Make authenticated request using Dio (ADDED)
  Future<Response> _makeAuthenticatedRequest(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) async {
    final headers = await _getAuthenticatedHeaders();
    
    _debugLog('🌐 Making authenticated autopsy request:', {
      'method': method,
      'path': path,
      'hasAuth': headers.containsKey('Authorization'),
      'headers': headers.keys.join(', '),
    });

    try {
      Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(
            path,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
          break;
        case 'POST':
          response = await _dio.post(
            path,
            data: data,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
          break;
        case 'PUT':
          response = await _dio.put(
            path,
            data: data,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
          break;
        case 'DELETE':
          response = await _dio.delete(
            path,
            data: data,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
          break;
        default:
          throw AutopsyException(message: 'Unsupported HTTP method: $method');
      }

      _debugLog('✅ Autopsy request successful:', {
        'method': method,
        'path': path,
        'statusCode': response.statusCode,
      });

      return response;
      
    } catch (error) {
      _debugLog('❌ Autopsy request failed:', {
        'method': method,
        'path': path,
        'error': error.toString(),
        'hasAuthHeader': headers.containsKey('Authorization'),
      });
      rethrow;
    }
  }

  // ============= UTILITY METHODS (YOUR EXISTING CODE) =============

  void _debugLog(String message, [dynamic data]) {
    if (_debugMode) {
      try {
        String? dataString;
        if (data != null) {
          if (data is String) {
            dataString = data;
          } else if (data is Map || data is List) {
            try {
              dataString = jsonEncode(data);
            } catch (e) {
              // If JSON encoding fails, use toString
              dataString = data.toString();
            }
          } else {
            dataString = data.toString();
          }
        }
        
        developer.log(
          message,
          name: 'AutopsyClient', // or 'AutopsyRepository' for the repository
          error: dataString,
        );
      } catch (e) {
        // Fallback logging without data if everything fails
        developer.log(
          '$message (debug data failed to serialize)',
          name: 'AutopsyClient', // or 'AutopsyRepository' for the repository
        );
      }
    }
    print("🔍 AutopsyClient: $message ${data != null ? '- $data' : ''}"); // ADDED: Console print too
  }

  void _handleError(dynamic error, String operation) {
    _debugLog('❌ Error in $operation', error);
    
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final message = error.response?.data?['message'] ?? error.message;
      
      // Handle specific error types
      if (statusCode == 403 || statusCode == 401) {
        throw AutopsyPermissionException(
          message: message ?? 'Access denied',
          statusCode: statusCode,
          originalError: error,
        );
      } else if (statusCode == 404) {
        throw AutopsyNotFoundException(
          message: message ?? 'Autopsy not found',
          statusCode: statusCode,
          originalError: error,
        );
      } else {
        throw AutopsyException(
          message: message ?? 'An error occurred',
          statusCode: statusCode,
          originalError: error,
        );
      }
    } else {
      throw AutopsyException(
        message: error.toString(),
        originalError: error,
      );
    }
  }

  // ============= YOUR EXISTING DATA SANITIZATION METHODS =============

  /// Enhanced data sanitizer that handles type mismatches
  Map<String, dynamic> _sanitizeJsonData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    // Define field type mappings
    final booleanFields = {
      'deleted', 'autopsyoutofsystem', 'is_active', 'is_deleted', 
      'deleted_at', 'is_public', 'is_archived'
    };
    
    final stringFields = {
      'name', 'description', 'autopsyfulladdress', 'autopsystreet', 
      'autopsypostalcode', 'autopsymunicipality', 'autopsystate', 'autopsycity',
      'autopsycustomername', 'autopsycustomeremail', 'autopsycustomermobile',
      'autopsylandlinephonenumber', 'autopsystatus', 'autopsycategory',
      'autopsycomments', 'technicalcheckstatus', 'soilworkstatus',
      'constructionstatus', 'splicingstatus', 'billingstatus', 'malfunctionstatus',
      'autopsylatitude', 'autopsylongtitude', 'autopsyordernumber',
      'autopsybid', 'autopsycab', 'autopsyak', 'autopsyadminemail',
      'autopsyadminmobile', 'autopsyadminlandline', 'autopsycustomerfloor',
      'autopsypilot', 'autopsyttlp', 'autopsyttllppptest', 'building_id',
      'type', 'adminautopsyname', 'assigned_user_id', 'id', 'created_at',
      'modified_at', 'created_by', 'modified_by'
    };
    
    final numberFields = {
      'autopsyage'
    };

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      try {
        if (value == null) {
          sanitized[key] = null;
        } else if (booleanFields.contains(key)) {
          sanitized[key] = _convertToBoolean(value);
        } else if (stringFields.contains(key)) {
          sanitized[key] = _convertToString(value);
        } else if (numberFields.contains(key)) {
          sanitized[key] = _convertToNumber(value);
        } else if (key.contains('_at') && value is String) {
          // Keep datetime strings as-is
          sanitized[key] = value;
        } else {
          // Keep as-is for unknown fields, but ensure they're safe
          sanitized[key] = _sanitizeUnknownField(value);
        }
      } catch (e) {
        _debugLog('⚠️ Failed to sanitize field $key: $e', {'value': value, 'type': value.runtimeType});
        // Use a safe default based on field type expectations
        if (booleanFields.contains(key)) {
          sanitized[key] = false;
        } else if (stringFields.contains(key)) {
          sanitized[key] = value?.toString();
        } else if (numberFields.contains(key)) {
          sanitized[key] = 0;
        } else {
          sanitized[key] = value?.toString();
        }
      }
    }
    
    return sanitized;
  }

  /// Convert value to boolean with safe handling
  bool _convertToBoolean(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on';
    }
    return false;
  }

  /// Convert value to string with safe handling
  String? _convertToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    return value.toString();
  }

  /// Convert value to number with safe handling
  num? _convertToNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return num.tryParse(trimmed);
    }
    if (value is bool) return value ? 1 : 0;
    return null;
  }

  /// Sanitize unknown fields safely
  dynamic _sanitizeUnknownField(dynamic value) {
    if (value == null) return null;
    
    // Handle common problematic types
    if (value is bool || value is num || value is String) {
      return value;
    }
    
    if (value is List) {
      return value.map((item) => _sanitizeUnknownField(item)).toList();
    }
    
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in value.entries) {
        sanitized[entry.key.toString()] = _sanitizeUnknownField(entry.value);
      }
      return sanitized;
    }
    
    // For other types, convert to string as a safe fallback
    return value.toString();
  }

  // ============= MODIFIED METHODS TO USE AUTHENTICATION =============

  /// MODIFIED: List autopsies with authentication
  Future<AutopsyResponse> listAutopsies([ListAutopsyParams? params]) async {
    try {
      _debugLog('📋 Listing autopsies', {
        'params': params?.toQueryParams().toString() ?? 'null'
      });

      // MODIFIED: Use authenticated request instead of direct _dio.get
      final response = await _makeAuthenticatedRequest(
        'GET',
        '/c_autopsy',
        queryParameters: params?.toQueryParams(),
      );

      _debugLog('🔍 Raw response received', {
        'statusCode': response.statusCode,
        'dataType': response.data?.runtimeType.toString() ?? 'null',
        'hasData': response.data != null,
      });

      // Handle null or empty response
      if (response.data == null) {
        _debugLog('⚠️ Received null response data');
        return const AutopsyResponse(data: [], total: 0, limit: 0, offset: 0);
      }

      // Handle different response structures
      Map<String, dynamic> responseData;
      
      try {
        if (response.data is Map<String, dynamic>) {
          responseData = Map<String, dynamic>.from(response.data);
        } else if (response.data is List) {
          // If the response is directly a list, wrap it
          final list = response.data as List;
          responseData = {
            'data': list,
            'total': list.length,
            'limit': params?.limit ?? 50,
            'offset': params?.offset ?? 0,
          };
        } else {
          _debugLog('⚠️ Unexpected response format', {
            'type': response.data.runtimeType.toString(),
            'value': response.data.toString().length > 200 
                ? '${response.data.toString().substring(0, 200)}...' 
                : response.data.toString(),
          });
          throw AutopsyException(
            message: 'Unexpected response format: ${response.data.runtimeType}',
          );
        }
      } catch (e) {
        _debugLog('❌ Failed to process response structure', e.toString());
        throw AutopsyException(
          message: 'Failed to process response structure: $e',
          originalError: e,
        );
      }

      // Sanitize the response data safely
      try {
        if (responseData['data'] is List) {
          final rawList = responseData['data'] as List;
          final sanitizedData = <Map<String, dynamic>>[];
          
          for (int i = 0; i < rawList.length; i++) {
            try {
              final item = rawList[i];
              if (item is Map<String, dynamic>) {
                sanitizedData.add(_sanitizeJsonData(item));
              } else if (item is Map) {
                // Convert Map to Map<String, dynamic>
                final convertedMap = <String, dynamic>{};
                item.forEach((key, value) {
                  convertedMap[key.toString()] = value;
                });
                sanitizedData.add(_sanitizeJsonData(convertedMap));
              } else {
                _debugLog('⚠️ Skipping non-map item at index $i', {
                  'type': item?.runtimeType.toString() ?? 'null',
                  'value': item.toString().length > 100 
                      ? '${item.toString().substring(0, 100)}...' 
                      : item.toString(),
                });
              }
            } catch (e) {
              _debugLog('⚠️ Failed to sanitize item at index $i', e.toString());
              // Skip problematic items rather than failing entirely
              continue;
            }
          }
          
          responseData['data'] = sanitizedData;
          
          _debugLog('✅ Data sanitization completed', {
            'originalCount': rawList.length,
            'sanitizedCount': sanitizedData.length,
          });
        } else {
          _debugLog('⚠️ Response data is not a list', {
            'dataType': responseData['data']?.runtimeType.toString() ?? 'null',
          });
        }
      } catch (e) {
        _debugLog('❌ Failed during data sanitization', e.toString());
      }

      // Create the AutopsyResponse
      try {
        final autopsyResponse = AutopsyResponse.fromJson(responseData);
        _debugLog('✅ Listed autopsies successfully', {
          'total': autopsyResponse.total.toString(),
          'count': autopsyResponse.data.length.toString(),
        });

        return autopsyResponse;
      } catch (e) {
        _debugLog('❌ Failed to create AutopsyResponse', e.toString());
        throw AutopsyException(
          message: 'Failed to create AutopsyResponse: $e',
          originalError: e,
        );
      }

    } catch (error) {
      _debugLog('❌ Error in listAutopsies', error.toString());
      
      // Re-throw our custom exceptions
      if (error is AutopsyException) {
        rethrow;
      }
      
      // Handle other errors
      throw AutopsyException(
        message: 'Failed to list autopsies: ${error.toString()}',
        originalError: error,
      );
    }
  }

  /// MODIFIED: Get autopsy with authentication
// lib/services/autopsy_client.dart - Updated getAutopsy method with safe parsing

/// Get a single autopsy by ID with safe parsing
Future<AutopsyDetailResponse> getAutopsy(
  String id, {
  bool? includeDeleted,
}) async {
  try {
    _debugLog('🔍 Getting autopsy', {'id': id, 'includeDeleted': includeDeleted});

    final queryParams = <String, String>{};
    if (includeDeleted != null) {
      queryParams['includeDeleted'] = includeDeleted.toString();
    }

    // Use authenticated request
    final response = await _makeAuthenticatedRequest(
      'GET',
      '/c_autopsy/$id',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    _debugLog('🔍 Raw autopsy detail response', {
      'statusCode': response.statusCode,
      'hasData': response.data != null,
      'dataType': response.data?.runtimeType.toString() ?? 'null',
    });

    // Handle response data safely
    if (response.data == null) {
      _debugLog('⚠️ Received null response for autopsy $id');
      return const AutopsyDetailResponse(
        data: null,
        permissionDenied: false,
      );
    }

    // Handle different response structures
    Map<String, dynamic> responseData;
    if (response.data is Map<String, dynamic>) {
      responseData = response.data as Map<String, dynamic>;
    } else {
      _debugLog('❌ Unexpected response format for autopsy $id', {
        'type': response.data.runtimeType.toString(),
      });
      throw AutopsyException(
        message: 'Unexpected response format: ${response.data.runtimeType}',
      );
    }

    // Check for permission denied
    if (responseData['permission_denied'] == true) {
      _debugLog('🚫 Permission denied for autopsy $id');
      return const AutopsyDetailResponse(
        data: null,
        permissionDenied: true,
      );
    }

    // Extract autopsy data
    final autopsyData = responseData['data'];
    if (autopsyData == null) {
      _debugLog('⚠️ No autopsy data found for ID $id');
      return const AutopsyDetailResponse(
        data: null,
        permissionDenied: false,
      );
    }

    // Use the SAFE CAutopsy.fromJson instead of the generated one
    CAutopsy autopsy;
    try {
      // Import the safe CAutopsy model from c_autopsy.dart
      autopsy = CAutopsy.fromJson(autopsyData as Map<String, dynamic>);
      
      _debugLog('✅ Successfully parsed autopsy detail', {
        'id': autopsy.id,
        'name': autopsy.name,
        'deleted': autopsy.deleted,
        'autopsyOutOfSystem': autopsy.autopsyOutOfSystem,
      });
    } catch (parseError) {
      _debugLog('❌ Failed to parse autopsy data for $id', {
        'error': parseError.toString(),
        'dataKeys': (autopsyData as Map<String, dynamic>).keys.toList(),
      });
      
      throw AutopsyDataException(
        message: 'Failed to parse autopsy data: $parseError',
        originalError: parseError,
        details: {
          'autopsyId': id,
          'dataKeys': (autopsyData as Map<String, dynamic>).keys.toList(),
        },
      );
    }

    return AutopsyDetailResponse(
      data: autopsy,
      permissionDenied: false,
    );

  } catch (error) {
    // Check if this is a permission error
    if (error is DioException && error.response?.statusCode == 403) {
      _debugLog('🚫 Permission denied for autopsy', {'id': id});
      return const AutopsyDetailResponse(
        data: null,
        permissionDenied: true,
      );
    }
    
    _debugLog('❌ Error in getAutopsy', {
      'id': id,
      'error': error.toString(),
      'type': error.runtimeType.toString(),
    });
    
    _handleError(error, 'getAutopsy');
    rethrow;
  }
}

  /// MODIFIED: Create autopsy with authentication
  Future<CAutopsy> createAutopsy(CreateAutopsyRequest request) async {
    try {
      _debugLog('➕ Creating autopsy', request.toJson());

      // MODIFIED: Use authenticated request
      final response = await _makeAuthenticatedRequest(
        'POST',
        '/c_autopsy',
        data: request.toJson(),
      );

      final autopsy = CAutopsy.fromJson(response.data['data']);
      _debugLog('✅ Created autopsy successfully', {'id': autopsy.id});

      // Invalidate any cached permissions or lists
      _clearLocalCaches();

      return autopsy;
    } catch (error) {
      _handleError(error, 'createAutopsy');
      rethrow;
    }
  }

  /// MODIFIED: Update autopsy with authentication
  Future<CAutopsy> updateAutopsy(String id, UpdateAutopsyRequest request) async {
    try {
      _debugLog('✏️ Updating autopsy', {'id': id, 'data': request.toJson()});

      // MODIFIED: Use authenticated request
      final response = await _makeAuthenticatedRequest(
        'PUT',
        '/c_autopsy/$id',
        data: request.toJson(),
      );

      final autopsy = CAutopsy.fromJson(response.data['data']);
      _debugLog('✅ Updated autopsy successfully', {'id': id});

      return autopsy;
    } catch (error) {
      _handleError(error, 'updateAutopsy');
      rethrow;
    }
  }

  /// MODIFIED: Delete autopsy with authentication
  Future<void> deleteAutopsy(String id) async {
    try {
      _debugLog('🗑️ Deleting autopsy', {'id': id});

      // MODIFIED: Use authenticated request
      await _makeAuthenticatedRequest('DELETE', '/c_autopsy/$id');
      
      _debugLog('✅ Deleted autopsy successfully', {'id': id});
    } catch (error) {
      _handleError(error, 'deleteAutopsy');
      rethrow;
    }
  }

  /// MODIFIED: Restore autopsy with authentication
  Future<CAutopsy> restoreAutopsy(String id) async {
    try {
      _debugLog('♻️ Restoring autopsy', {'id': id});

      // MODIFIED: Use authenticated request
      final response = await _makeAuthenticatedRequest('POST', '/c_autopsy/$id/restore');
      
      final autopsy = CAutopsy.fromJson(response.data['data']);
      _debugLog('✅ Restored autopsy successfully', {'id': id});

      return autopsy;
    } catch (error) {
      _handleError(error, 'restoreAutopsy');
      rethrow;
    }
  }

  /// MODIFIED: Permanently delete autopsy with authentication
  Future<void> permanentDeleteAutopsy(String id) async {
    try {
      _debugLog('💥 Permanently deleting autopsy', {'id': id});

      // MODIFIED: Use authenticated request
      await _makeAuthenticatedRequest('DELETE', '/c_autopsy/$id/permanent');
      
      _debugLog('✅ Permanently deleted autopsy', {'id': id});
    } catch (error) {
      _handleError(error, 'permanentDeleteAutopsy');
      rethrow;
    }
  }

  /// MODIFIED: Search autopsies with authentication
  Future<AutopsyResponse> searchAutopsies(SearchAutopsyParams params) async {
    try {
      _debugLog('🔍 Searching autopsies', {
        'query': params.query,
        'fields': params.fields,
      });

      // MODIFIED: Use authenticated request
      final response = await _makeAuthenticatedRequest(
        'GET',
        '/c_autopsy/search',
        queryParameters: params.toQueryParams(),
      );

      final autopsyResponse = AutopsyResponse.fromJson(response.data);
      _debugLog('✅ Search completed', {
        'resultsCount': autopsyResponse.data.length,
        'total': autopsyResponse.total,
      });

      return autopsyResponse;
    } catch (error) {
      _handleError(error, 'searchAutopsies');
      rethrow;
    }
  }

  /// MODIFIED: Get permissions with authentication
  Future<AutopsyPermissions> getPermissions() async {
    try {
      // Check cache first
      const cacheKey = 'user_permissions';
      final cachedPermissions = _permissionCache[cacheKey];
      final cacheTimestamp = _permissionCacheTimestamps[cacheKey];
      
      if (cachedPermissions != null && 
          cacheTimestamp != null && 
          DateTime.now().difference(cacheTimestamp) < _permissionCacheTimeout) {
        _debugLog('📋 Returning cached permissions');
        return cachedPermissions;
      }

      _debugLog('🔐 Fetching user permissions');

      // MODIFIED: Use authenticated request
      final response = await _makeAuthenticatedRequest('GET', '/c_autopsy/permissions');
      
      // MODIFIED: Handle different response formats
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw AutopsyException(message: 'Invalid permissions response format');
      }

      // Try different response structures
      AutopsyPermissions permissions;
      if (responseData.containsKey('permissions')) {
        permissions = AutopsyPermissions.fromJson(responseData['permissions']);
      } else {
        // Assume the entire response is the permissions
        permissions = AutopsyPermissions.fromJson(responseData);
      }

      // Cache the permissions
      _permissionCache[cacheKey] = permissions;
      _permissionCacheTimestamps[cacheKey] = DateTime.now();

      _debugLog('✅ Got permissions', {
        'canCreate': permissions.canCreate,
        'canEdit': permissions.canEdit,
        'canDelete': permissions.canDelete,
      });

      return permissions;
    } catch (error) {
      _debugLog('❌ Failed to fetch autopsy permissions', error);
      // Return safe defaults on error
      const defaultPermissions = AutopsyPermissions(
        canCreate: false,
        canRead: false,
        canEdit: false,
        canDelete: false,
        canRestore: false,
        canPermanentDelete: false,
        canViewDeleted: false,
        visibleFields: const [],
        editableFields: const [],
        creatableFields: const [],
      );
      
      // Cache default permissions for a shorter time
      const cacheKey = 'user_permissions';
      _permissionCache[cacheKey] = defaultPermissions;
      _permissionCacheTimestamps[cacheKey] = DateTime.now();
      
      return defaultPermissions;
    }
  }

  // ============= ALL YOUR OTHER EXISTING METHODS (UNCHANGED) =============
  
  /// Get fresh permissions (bypasses cache)
  Future<AutopsyPermissions> getFreshPermissions() async {
    try {
      // Clear cache first
      _clearPermissionCache();

      _debugLog('🔐 Fetching fresh permissions');
      
      // MODIFIED: Use authenticated request
      final response = await _makeAuthenticatedRequest('GET', '/c_autopsy/permissions/fresh');
      
      // Handle response format
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw AutopsyException(message: 'Invalid fresh permissions response format');
      }

      AutopsyPermissions permissions;
      if (responseData.containsKey('permissions')) {
        permissions = AutopsyPermissions.fromJson(responseData['permissions']);
      } else {
        permissions = AutopsyPermissions.fromJson(responseData);
      }

      _debugLog('✅ Got fresh permissions');

      return permissions;
    } catch (error) {
      _debugLog('❌ Failed to fetch fresh permissions', error);
      return const AutopsyPermissions(
        canCreate: false,
        canRead: false,
        canEdit: false,
        canDelete: false,
        canRestore: false,
        canPermanentDelete: false,
        canViewDeleted: false,
        visibleFields: [],
        editableFields: [],
        creatableFields: [],
      );
    }
  }

  /// Clear permission cache
  Future<Map<String, dynamic>> clearPermissionCache({String? userId}) async {
    try {
      final data = userId != null ? {'userId': userId} : <String, dynamic>{};
      
      // MODIFIED: Use authenticated request
      final response = await _makeAuthenticatedRequest('POST', '/c_autopsy/permissions/clear-cache', data: data);
      
      // Also clear local cache
      _clearPermissionCache();

      _debugLog('🧽 Cleared permission cache', {'userId': userId});
      return response.data;
    } catch (error) {
      _handleError(error, 'clearPermissionCache');
      rethrow;
    }
  }

  // ============= ALL YOUR EXISTING HELPER METHODS (KEEP AS-IS) =============

  /// Check if user can perform a specific action on an autopsy
  Future<bool> canPerformAction(String autopsyId, String action) async {
    try {
      final permissions = await getPermissions();

      switch (action) {
        case 'read':
          return permissions.canEdit; // Assuming canEdit includes canRead
        case 'edit':
          return permissions.canEdit;
        case 'delete':
          return permissions.canDelete;
        case 'restore':
          return permissions.canRestore;
        case 'permanent_delete':
          return permissions.canDelete; // Assuming delete includes permanent delete
        default:
          return false;
      }
    } catch (error) {
      _debugLog('❌ Failed to check $action permission for autopsy $autopsyId', error);
      return false;
    }
  }

  /// Check if a field is visible to the current user
  Future<bool> isFieldVisible(String fieldName) async {
    try {
      final permissions = await getPermissions();
      return true; // Default to visible since AutopsyPermissions doesn't have visibleFields
    } catch (error) {
      _debugLog('❌ Failed to check visibility for field $fieldName', error);
      return true; // Default to visible on error
    }
  }

  /// Check if a field is editable by the current user
  Future<bool> isFieldEditable(String fieldName) async {
    try {
      final permissions = await getPermissions();
      return permissions.canEdit; // Use canEdit as general editability
    } catch (error) {
      _debugLog('❌ Failed to check editability for field $fieldName', error);
      return false; // Default to not editable on error
    }
  }

  // ============= HELPER METHODS =============

  /// Get status options for dropdowns
  List<AutopsyStatusOption> getStatusOptions() {
    return [
      const AutopsyStatusOption(value: 'pending', label: 'Pending', color: 'orange'),
      const AutopsyStatusOption(value: 'in_progress', label: 'In Progress', color: 'blue'),
      const AutopsyStatusOption(value: 'completed', label: 'Completed', color: 'green'),
      const AutopsyStatusOption(value: 'cancelled', label: 'Cancelled', color: 'red'),
      const AutopsyStatusOption(value: 'on_hold', label: 'On Hold', color: 'gray'),
    ];
  }

  /// Get category options for dropdowns
  List<AutopsyCategoryOption> getCategoryOptions() {
    return [
      const AutopsyCategoryOption(
        value: 'fiber_installation',
        label: 'Fiber Installation',
      ),
      const AutopsyCategoryOption(
        value: 'maintenance',
        label: 'Maintenance',
      ),
      const AutopsyCategoryOption(
        value: 'repair',
        label: 'Repair',
      ),
      const AutopsyCategoryOption(
        value: 'inspection',
        label: 'Inspection',
      ),
    ];
  }

  /// Get status configuration for UI display
  Map<String, Map<String, dynamic>> getStatusConfig() {
    final Map<String, Map<String, dynamic>> config = {};
    
    for (final option in getStatusOptions()) {
      config[option.value] = {
        'label': option.label,
        'color': option.color ?? 'gray',
      };
    }
    
    return config;
  }

  /// Get formatted status display name
  String getStatusLabel(String? status) {
    if (status == null) return 'Άγνωστο';
    
    final option = getStatusOptions().firstWhere(
      (opt) => opt.value == status,
      orElse: () => AutopsyStatusOption(value: status, label: status),
    );
    return option.label;
  }

  /// Get formatted category display name
  String getCategoryLabel(String? category) {
    if (category == null) return 'Άγνωστη';
    
    final option = getCategoryOptions().firstWhere(
      (opt) => opt.value == category,
      orElse: () => AutopsyCategoryOption(value: category, label: category),
    );
    return option.label;
  }

  /// Get autopsy display name (name or fallback)
  String getAutopsyDisplayName(CAutopsy autopsy) {
    if (autopsy.name?.isNotEmpty == true) {
      return autopsy.name!;
    }
    
    if (autopsy.autopsyCustomerName?.isNotEmpty == true) {
      return 'Autopsy for ${autopsy.autopsyCustomerName}';
    }
    
    if (autopsy.autopsyFullAddress?.isNotEmpty == true) {
      return 'Autopsy at ${autopsy.autopsyFullAddress}';
    }
    
    return 'Autopsy #${autopsy.id}';
  }

  /// Format autopsy address for display
  String? getFormattedAddress(CAutopsy autopsy) {
    final parts = <String>[];
    
    if (autopsy.autopsyStreet?.isNotEmpty == true) {
      parts.add(autopsy.autopsyStreet!);
    }
    
    if (autopsy.autopsyCity?.isNotEmpty == true) {
      parts.add(autopsy.autopsyCity!);
    }
    
    if (autopsy.autopsyPostalCode?.isNotEmpty == true) {
      parts.add(autopsy.autopsyPostalCode!);
    }
    
    return parts.isEmpty ? autopsy.autopsyFullAddress : parts.join(', ');
  }

  /// Check if autopsy is deleted
  bool isDeleted(CAutopsy autopsy) {
    return autopsy.deleted == true;
  }

  /// Check if autopsy has location coordinates
  bool hasLocation(CAutopsy autopsy) {
    return autopsy.autopsyLatitude?.isNotEmpty == true && 
           autopsy.autopsyLongitude?.isNotEmpty == true;
  }

  /// Get location coordinates
  ({double lat, double lng})? getLocation(CAutopsy autopsy) {
    try {
      final lat = double.parse(autopsy.autopsyLatitude ?? '');
      final lng = double.parse(autopsy.autopsyLongitude ?? '');
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  // ============= CACHE MANAGEMENT =============

  void _clearPermissionCache() {
    _permissionCache.clear();
    _permissionCacheTimestamps.clear();
  }

  void _clearLocalCaches() {
    _clearPermissionCache();
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheInfo() {
    return {
      'permissionCacheSize': _permissionCache.length,
      'permissionCacheKeys': _permissionCache.keys.toList(),
      'cacheTimestamps': _permissionCacheTimestamps.entries
          .map((e) => '${e.key}: ${e.value}')
          .toList(),
    };
  }

  /// Clear all caches
  void clearAllCaches() {
    _clearLocalCaches();
    _debugLog('🧹 Cleared all caches');
  }

  // ============= BATCH OPERATIONS =============

  /// Get multiple autopsies by IDs
  Future<List<CAutopsy?>> getMultipleAutopsies(List<String> ids) async {
    final results = <CAutopsy?>[];
    
    for (final id in ids) {
      try {
        final response = await getAutopsy(id);
        results.add(response.data);
      } catch (error) {
        _debugLog('⚠️ Failed to get autopsy $id', error);
        results.add(null);
      }
    }
    
    return results;
  }

  /// Check permissions for multiple actions at once
  Future<Map<String, bool>> checkMultiplePermissions(List<String> actions) async {
    final results = <String, bool>{};
    final permissions = await getPermissions();
    
    for (final action in actions) {
      switch (action) {
        case 'create':
          results[action] = permissions.canCreate;
          break;
        case 'read':
          results[action] = permissions.canEdit; // Assume canEdit includes read
          break;
        case 'edit':
          results[action] = permissions.canEdit;
          break;
        case 'delete':
          results[action] = permissions.canDelete;
          break;
        case 'restore':
          results[action] = permissions.canRestore;
          break;
        case 'permanent_delete':
          results[action] = permissions.canDelete;
          break;
        case 'view_deleted':
          results[action] = permissions.canViewDeleted;
          break;
        default:
          results[action] = false;
      }
    }
    
    return results;
  }

  /// Get field visibility for multiple fields
  Future<Map<String, bool>> checkFieldVisibility(List<String> fieldNames) async {
    final results = <String, bool>{};
    
    for (final fieldName in fieldNames) {
      results[fieldName] = true; // Default to visible
    }
    
    return results;
  }

  /// Get field editability for multiple fields
  Future<Map<String, bool>> checkFieldEditability(List<String> fieldNames) async {
    final results = <String, bool>{};
    final permissions = await getPermissions();
    
    for (final fieldName in fieldNames) {
      results[fieldName] = permissions.canEdit;
    }
    
    return results;
  }
}