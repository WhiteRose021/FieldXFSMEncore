// lib/services/autopsy_service.dart - DEBUG VERSION

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/autopsy_models.dart';
import '../config/backend_config.dart';
import 'backend_service.dart';
import 'dart:convert';

class AutopsyService {
  final BackendService _backend = BackendService.instance;

  AutopsyService() {
    developer.log('🚀 AutopsyService initialized', name: 'AutopsyService');
    _logBackendStatus();
  }

  void _logBackendStatus() async {
    try {
      developer.log('🔧 Checking backend status...', name: 'AutopsyService');

      final apiUrl = await _backend.getApiBaseUrl();
      final environment = await BackendConfig.getEnvironment();
      final tenant = await BackendConfig.getTenant();

      developer.log('📊 Backend Status:', name: 'AutopsyService');
      developer.log('  API URL: $apiUrl', name: 'AutopsyService');
      developer.log('  Environment: $environment', name: 'AutopsyService');
      developer.log('  Tenant: $tenant', name: 'AutopsyService');

      print('🔵 CONSOLE: Backend Status - API: $apiUrl, Env: $environment, Tenant: $tenant');
    } catch (e) {
      developer.log('❌ Backend status check failed: $e', name: 'AutopsyService');
      print('🔴 CONSOLE ERROR: Backend status check failed: $e');
    }
  }

  // ============= MAIN API METHODS WITH DEBUG =============

  /// List autopsies with extensive debugging
  Future<AutopsyResponse> listAutopsies(ListAutopsyParams params) async {
    developer.log('🎯 START listAutopsies', name: 'AutopsyService');
    print('🟢 CONSOLE: Starting listAutopsies with params: ${params.toJson()}');
    
    try {
      // Step 1: Log the request
      developer.log('📝 Building query parameters', name: 'AutopsyService');
      final queryParams = <String, dynamic>{};
      
      if (params.limit != null) queryParams['limit'] = params.limit;
      if (params.offset != null) queryParams['offset'] = params.offset;
      if (params.orderBy != null) queryParams['orderBy'] = params.orderBy;
      if (params.orderDirection != null) queryParams['orderDirection'] = params.orderDirection;
      if (params.search != null) queryParams['search'] = params.search;
      if (params.status != null) queryParams['status'] = params.status;
      if (params.category != null) queryParams['category'] = params.category;
      if (params.includeDeleted != null) queryParams['includeDeleted'] = params.includeDeleted;
      if (params.onlyDeleted != null) queryParams['onlyDeleted'] = params.onlyDeleted;

      queryParams.removeWhere((key, value) => value == null);
      
      developer.log('📋 Query params: $queryParams', name: 'AutopsyService');
      print('🟡 CONSOLE: Query params prepared: $queryParams');

      // Step 2: Check backend service
      developer.log('🔌 Checking backend service availability', name: 'AutopsyService');
      final apiUrl = await _backend.getApiBaseUrl();
      developer.log('🌐 API Base URL: $apiUrl', name: 'AutopsyService');
      print('🟡 CONSOLE: API Base URL: $apiUrl');

      // Step 3: Make the API call
      developer.log('📡 Making API call to /c_autopsy', name: 'AutopsyService');
      print('🟡 CONSOLE: Making API call to /c_autopsy');
      
      final response = await _backend.get('/c_autopsy', queryParameters: queryParams);
      print('📦 RAW JSON RESPONSE:\n${response.data}');
      print('📦 RAW JSON RESPONSE (encoded):');
      print(const JsonEncoder.withIndent('  ').convert(response.data));

      developer.log('✅ API call successful', name: 'AutopsyService');
      developer.log('📊 Response status: ${response.statusCode}', name: 'AutopsyService');
      developer.log('📦 Response data type: ${response.data.runtimeType}', name: 'AutopsyService');
      
      print('🟢 CONSOLE: API Response received - Status: ${response.statusCode}');
      print('🟢 CONSOLE: Response data keys: ${response.data?.keys?.toList()}');

      // Step 4: Parse the response
      developer.log('🔄 Parsing response to AutopsyResponse', name: 'AutopsyService');
      
      // Debug the response structure
      if (response.data != null) {
        developer.log('📋 Response structure:', name: 'AutopsyService');
        if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          developer.log('  Keys: ${dataMap.keys.toList()}', name: 'AutopsyService');
          
          if (dataMap.containsKey('data')) {
            final dataList = dataMap['data'];
            developer.log('  Data type: ${dataList.runtimeType}', name: 'AutopsyService');
            if (dataList is List) {
              developer.log('  Data length: ${dataList.length}', name: 'AutopsyService');
              print('🟢 CONSOLE: Found ${dataList.length} autopsies in response');
            }
          }
          
          if (dataMap.containsKey('total')) {
            developer.log('  Total: ${dataMap['total']}', name: 'AutopsyService');
          }
        }
      }

      final result = AutopsyResponse.fromJson(response.data);
      
      developer.log('✅ Response parsed successfully', name: 'AutopsyService');
      developer.log('📊 Result: ${result.data.length} autopsies, total: ${result.total}', name: 'AutopsyService');
      print('🟢 CONSOLE SUCCESS: Listed ${result.data.length} autopsies, total: ${result.total}');
      
      return result;
      
    } catch (error, stackTrace) {
      developer.log('❌ ERROR in listAutopsies:', name: 'AutopsyService');
      developer.log('❌ Error: $error', name: 'AutopsyService');
      developer.log('❌ Stack trace: $stackTrace', name: 'AutopsyService');
      
      print('🔴 CONSOLE ERROR: listAutopsies failed');
      print('🔴 CONSOLE ERROR: $error');
      print('🔴 CONSOLE STACK: $stackTrace');
      
      // Try to identify the specific error type
      if (error.toString().contains('SocketException')) {
        print('🔴 CONSOLE: Network connectivity issue - check if backend is running');
      } else if (error.toString().contains('FormatException')) {
        print('🔴 CONSOLE: JSON parsing issue - response format mismatch');
      } else if (error.toString().contains('401') || error.toString().contains('403')) {
        print('🔴 CONSOLE: Authentication/permission issue');
      } else if (error.toString().contains('404')) {
        print('🔴 CONSOLE: Endpoint not found - check backend API routes');
      }
      
      throw _handleError(error, 'Failed to list autopsies');
    }
  }

  /// Test different parameter combinations to find what works
  Future<Map<String, dynamic>> testParameterCombinations() async {
    developer.log('🧪 Testing different parameter combinations', name: 'AutopsyService');
    print('🟡 CONSOLE: Testing parameter combinations...');
    
    final tests = [
      // Test 1: Minimal request
      {'name': 'minimal', 'params': {'limit': 5}},
      
      // Test 2: With different orderBy field names
      {'name': 'orderBy_modified_at', 'params': {'limit': 5, 'orderBy': 'modified_at'}},
      {'name': 'orderBy_created_at', 'params': {'limit': 5, 'orderBy': 'created_at'}},
      {'name': 'orderBy_id', 'params': {'limit': 5, 'orderBy': 'id'}},
      {'name': 'orderBy_name', 'params': {'limit': 5, 'orderBy': 'name'}},
      
      // Test 3: With different orderDirection values
      {'name': 'orderDirection_ASC', 'params': {'limit': 5, 'orderBy': 'modified_at', 'orderDirection': 'ASC'}},
      {'name': 'orderDirection_DESC', 'params': {'limit': 5, 'orderBy': 'modified_at', 'orderDirection': 'DESC'}},
      
      // Test 4: Without orderBy
      {'name': 'no_orderBy', 'params': {'limit': 5, 'offset': 0}},
    ];
    
    final results = <String, dynamic>{};
    
    for (final test in tests) {
      final testName = test['name'] as String;
      final params = test['params'] as Map<String, dynamic>;
      
      try {
        print('🔍 CONSOLE: Testing $testName with params: $params');
        
        final response = await _backend.get('/c_autopsy', queryParameters: params);
        
        results[testName] = {
          'status': 'success',
          'statusCode': response.statusCode,
          'dataCount': (response.data['data'] as List?)?.length ?? 0,
          'total': response.data['total'],
        };
        
        print('✅ CONSOLE: $testName succeeded - ${results[testName]}');
        
      } catch (e) {
        results[testName] = {
          'status': 'failed',
          'error': e.toString(),
        };
        
        print('❌ CONSOLE: $testName failed - ${e.toString().split('\n').first}');
      }
    }
    
    return results;
  }
     /// ✅ FIXED: Wrapped properly as a method
  Future<Map<String, dynamic>> testBackendConnectivity() async {
    developer.log('🧪 Testing backend connectivity', name: 'AutopsyService');
    print('🟡 CONSOLE: Testing backend connectivity...');

    try {
      final apiUrl = await _backend.getApiBaseUrl();
      developer.log('✅ Base URL test passed: $apiUrl', name: 'AutopsyService');

      try {
        final response = await _backend.get('/health').timeout(Duration(seconds: 5));
        developer.log('✅ Health check passed', name: 'AutopsyService');
        print('🟢 CONSOLE: Backend health check passed');
      } catch (e) {
        developer.log('⚠️ Health check failed (might not be implemented): $e', name: 'AutopsyService');
        print('🟡 CONSOLE: Health check endpoint not available (normal)');
      }

      try {
        final response = await _backend.get('/c_autopsy', queryParameters: {'limit': 1})
            .timeout(Duration(seconds: 10));
        developer.log('✅ Autopsy endpoint test passed', name: 'AutopsyService');
        print('🟢 CONSOLE: Autopsy endpoint is accessible');

        return {
          'status': 'success',
          'apiUrl': apiUrl,
          'endpointTest': 'passed',
          'responseStatus': response.statusCode,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        developer.log('❌ Autopsy endpoint test failed: $e', name: 'AutopsyService');
        print('🔴 CONSOLE: Autopsy endpoint test failed: $e');

        return {
          'status': 'endpoint_failed',
          'apiUrl': apiUrl,
          'endpointError': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

    } catch (e) {
      developer.log('❌ Backend connectivity test failed: $e', name: 'AutopsyService');
      print('🔴 CONSOLE: Backend connectivity test failed: $e');

      return {
        'status': 'failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }


  // ============= SIMPLE METHODS FOR TESTING =============

  /// Create a minimal test autopsy list (fallback)
  Future<AutopsyResponse> createTestAutopsyList() async {
    developer.log('🧪 Creating test autopsy list', name: 'AutopsyService');
    print('🟡 CONSOLE: Creating test autopsy list as fallback');
    
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    final testAutopsy = CAutopsy(
      id: 'test-123',
      name: 'Test Autopsy',
      autopsyCustomerName: 'Test Customer',
      autopsyFullAddress: '123 Test Street',
      autopsyStatus: 'pending',
      autopsyCategory: 'test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return AutopsyResponse(
      data: [testAutopsy],
      total: 1,
      limit: 20,
      offset: 0,
    );
  }

  // ============= OTHER METHODS (SIMPLIFIED FOR DEBUG) =============

  Future<SingleAutopsyResponse> getAutopsy(String id) async {
    print('🟡 CONSOLE: getAutopsy called with ID: $id');
    throw UnimplementedError('getAutopsy not implemented in debug version');
  }

  Future<CAutopsy> createAutopsy(CreateAutopsyRequest request) async {
    print('🟡 CONSOLE: createAutopsy called');
    throw UnimplementedError('createAutopsy not implemented in debug version');
  }

  Future<CAutopsy> updateAutopsy(String id, UpdateAutopsyRequest request) async {
    print('🟡 CONSOLE: updateAutopsy called with ID: $id');
    throw UnimplementedError('updateAutopsy not implemented in debug version');
  }

  Future<void> deleteAutopsy(String id) async {
    print('🟡 CONSOLE: deleteAutopsy called with ID: $id');
    throw UnimplementedError('deleteAutopsy not implemented in debug version');
  }

  Future<AutopsyResponse> searchAutopsies(SearchAutopsyParams params) async {
    print('🟡 CONSOLE: searchAutopsies called with query: ${params.query}');
    return listAutopsies(ListAutopsyParams(search: params.query, limit: params.limit));
  }

  // ============= UTILITY METHODS =============

  Future<CAutopsy> restoreAutopsy(String id) async {
    throw UnimplementedError('Restore autopsy functionality not available in backend');
  }

  Future<AutopsyPermissions> getPermissions() async {
    return AutopsyPermissions(
      canRead: true,
      canEdit: true,
      canCreate: true,
      canDelete: true,
      canRestore: false,
      canPermanentDelete: false,
      canViewDeleted: true,
      visibleFields: [],
      editableFields: [],
      creatableFields: [],
    );
  }

  String getStatusLabel(String? status) {
    return AutopsyOptions.getStatusLabel(status) ?? status ?? 'Unknown';
  }

  String getCategoryLabel(String? category) {
    return AutopsyOptions.getCategoryLabel(category) ?? category ?? 'Unknown';
  }

  List<AutopsyStatusOption> getStatusOptions() {
    return AutopsyOptions.statusOptions;
  }

  List<AutopsyCategoryOption> getCategoryOptions() {
    return AutopsyOptions.categoryOptions;
  }

  String getAutopsyDisplayName(CAutopsy autopsy) {
    return autopsy.effectiveDisplayName;
  }

  String? getFormattedAddress(CAutopsy autopsy) {
    final address = autopsy.fullAddress;
    return address.isNotEmpty ? address : null;
  }

  Exception _handleError(dynamic error, String defaultMessage) {
    developer.log('🔥 Handling error: $error', name: 'AutopsyService');
    print('🔴 CONSOLE: Error handler called: $error');

    final errorString = error.toString().toLowerCase();
    
    // ENHANCED: Better 400 error handling
    if (errorString.contains('400') || errorString.contains('bad request')) {
      print('🔴 CONSOLE: 400 Bad Request - likely invalid query parameters');
      print('🔴 CONSOLE: Check if field names match backend expectations (e.g., modified_at vs modifiedAt)');
      return AutopsyValidationException(message: 'Invalid request parameters. Check field names and values.');
    } else if (errorString.contains('404') || errorString.contains('not found')) {
      return AutopsyNotFoundException(message: 'Autopsy not found');
    } else if (errorString.contains('403') || errorString.contains('forbidden')) {
      return AutopsyPermissionException(message: 'Permission denied');
    } else if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return AutopsyPermissionException(message: 'Authentication required');
    } else if (errorString.contains('422') || errorString.contains('validation')) {
      return AutopsyValidationException(message: 'Validation failed');
    } else if (errorString.contains('timeout') || errorString.contains('connection')) {
      return AutopsyNetworkException(message: 'Network error');
    } else if (errorString.contains('500') || errorString.contains('internal server')) {
      return AutopsyException(message: 'Server error');
    }

    return AutopsyException(message: defaultMessage);
  }

  Future<void> refreshConfiguration() async {
    try {
      await _backend.refreshConfiguration();
      developer.log('✅ Configuration refreshed', name: 'AutopsyService');
      print('🟢 CONSOLE: Configuration refreshed');
    } catch (e) {
      developer.log('❌ Error refreshing configuration: $e', name: 'AutopsyService');
      print('🔴 CONSOLE: Error refreshing configuration: $e');
    }
  }
}