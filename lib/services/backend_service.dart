// lib/services/backend_service.dart
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/backend_config.dart';

/// Core service for managing Encore.ts backend communication
/// Handles environment switching, auth, and HTTP setup
class BackendService {
  static BackendService? _instance;
  Dio? _dio;
  
  String? _authToken;
  
  // Private constructor for singleton
  BackendService._internal();
  
  /// Get singleton instance
  static BackendService get instance {
    _instance ??= BackendService._internal();
    return _instance!;
  }

  /// Initialize the backend service
  Future<void> initialize({
    String? authToken,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _authToken = authToken;
    
    // Get API URL from BackendConfig instead of hardcoding
    final apiBaseUrl = await BackendConfig.getApiBaseUrl();
    
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: await _getDefaultHeaders(),
    ));

    _setupInterceptors();
    
    developer.log(
      'BackendService initialized - URL: $apiBaseUrl',
      name: 'BackendService',
    );
  }

  /// Refresh configuration (call this after environment changes)
  Future<void> refreshConfiguration() async {
    try {
      // Get updated API URL from BackendConfig
      final apiBaseUrl = await BackendConfig.getApiBaseUrl();
      final environment = await BackendConfig.getEnvironment();
      
      // Recreate Dio instance with new base URL
      _dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: await _getDefaultHeaders(),
      ));

      _setupInterceptors();
      
      developer.log(
        'BackendService configuration refreshed - Environment: $environment, URL: $apiBaseUrl',
        name: 'BackendService',
      );
    } catch (e) {
      developer.log('Error refreshing BackendService configuration: $e', name: 'BackendService');
    }
  }

  /// Get current API base URL from BackendConfig
  Future<String> getApiBaseUrl() async {
    return await BackendConfig.getApiBaseUrl();
  }

  /// Get current environment
  String get currentEnvironment => 'development'; // This will be updated by refreshConfiguration

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    
    // Update headers in existing Dio instance
    if (_dio != null) {
      _dio!.options.headers['Authorization'] = 'Bearer $token';
    }
    
    developer.log('Auth token set in BackendService', name: 'BackendService');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    
    // Remove auth header from Dio instance
    if (_dio != null) {
      _dio!.options.headers.remove('Authorization');
    }
    
    developer.log('Auth token cleared from BackendService', name: 'BackendService');
  }

  /// Get default headers including auth if available
  Future<Map<String, String>> _getDefaultHeaders() async {
    final headers = await BackendConfig.getDefaultHeaders();
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  /// Setup interceptors for logging and error handling
  void _setupInterceptors() {
    if (_dio == null) return;
    
    _dio!.interceptors.clear();
    
    // Add logging interceptor
    _dio!.interceptors.add(
      LogInterceptor(
        requestBody: kDebugMode,
        responseBody: kDebugMode,
        logPrint: (obj) => developer.log(obj.toString(), name: 'HTTP'),
      ),
    );

    // Add auth token interceptor
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Ensure auth token is always included if available
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          developer.log(
            'HTTP Error: ${error.response?.statusCode} - ${error.message}',
            name: 'BackendService',
          );
          handler.next(error);
        },
      ),
    );
  }

  /// Check if service is initialized
  bool _isInitialized() => _dio != null;

  /// Get configured HTTP client
  Dio getHttpClient() {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized. Call initialize() first.');
    }
    return _dio!;
  }

  /// Make a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    
    developer.log('GET $path', name: 'BackendService');
    
    return await _dio!.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    
    developer.log('POST $path', name: 'BackendService');
    
    return await _dio!.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    
    developer.log('PUT $path', name: 'BackendService');
    
    return await _dio!.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    
    developer.log('DELETE $path', name: 'BackendService');
    
    return await _dio!.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}