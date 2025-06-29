// lib/services/backend_service.dart - CORE FOUNDATION
// Following FSM Architecture PLAN - Single source for Encore.ts communication

import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Core service for managing Encore.ts backend communication
/// Handles environment switching, auth, and HTTP setup
class BackendService {
  static BackendService? _instance;
  Dio? _dio;
  
  // Environment configuration
  String _environment = 'development';
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
    String environment = 'development',
    String? authToken,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _environment = environment;
    _authToken = authToken;
    
    _dio = Dio(BaseOptions(
      baseUrl: getApiBaseUrl(),
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: _getDefaultHeaders(),
    ));

    _setupInterceptors();
    
    developer.log(
      'BackendService initialized - Environment: $_environment, URL: ${getApiBaseUrl()}',
      name: 'BackendService',
    );
  }

  /// Get current Encore.ts API base URL based on environment
  String getApiBaseUrl() {
    switch (_environment) {
      case 'production':
        return 'https://applink.fieldx.gr';
      case 'staging':
        return 'https://staging.fieldx.gr'; // If you have staging
      case 'development':
      default:
        return 'http://localhost:4000'; // Encore.ts local development
    }
  }

  /// Get configured HTTP client with auth and interceptors
  Dio getHttpClient() {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized. Call initialize() first.');
    }
    return _dio!;
  }

  /// Set authentication token for all requests
  void setAuthToken(String token) {
    _authToken = token;
    _dio?.options.headers['Authorization'] = 'Bearer $token';
    
    developer.log('Auth token updated', name: 'BackendService');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    _dio?.options.headers.remove('Authorization');
    
    developer.log('Auth token cleared', name: 'BackendService');
  }

  /// Switch environment and update base URL
  Future<void> setEnvironment(String environment) async {
    if (_environment == environment) return;
    
    _environment = environment;
    final newBaseUrl = getApiBaseUrl();
    
    if (_dio != null) {
      _dio!.options.baseUrl = newBaseUrl;
    }
    
    developer.log(
      'Environment switched to $_environment - URL: $newBaseUrl',
      name: 'BackendService',
    );
  }

  /// Get current environment
  String get currentEnvironment => _environment;

  /// Check if service is initialized
  bool _isInitialized() => _dio != null;

  /// Get default headers for all requests
  Map<String, dynamic> _getDefaultHeaders() {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'FieldFSM-Mobile/1.0',
    };

    // Add auth token if available
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Setup interceptors for logging and error handling
  void _setupInterceptors() {
    if (_dio == null) return;
    
    // Request/Response logging in debug mode
    if (kDebugMode) {
      _dio!.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false, // Don't log headers (may contain sensitive data)
        responseHeader: false,
        logPrint: (object) => developer.log(
          object.toString(),
          name: 'HTTP [${_environment.toUpperCase()}]',
        ),
      ));
    }

    // Auth token refresh interceptor
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Ensure auth token is always up to date
        if (_authToken != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Log errors for debugging
        developer.log(
          'HTTP Error: ${error.response?.statusCode} - ${error.message}',
          name: 'BackendService',
          error: error,
        );
        handler.next(error);
      },
    ));
  }

  /// Dispose resources
  void dispose() {
    _dio?.close();
    _instance = null;
    
    developer.log('BackendService disposed', name: 'BackendService');
  }

  /// Make a GET request to Encore.ts API
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    return await _dio!.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a POST request to Encore.ts API
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    return await _dio!.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a PUT request to Encore.ts API
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    return await _dio!.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a DELETE request to Encore.ts API
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_isInitialized()) {
      throw StateError('BackendService not initialized');
    }
    return await _dio!.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Environment constants for easy switching
class BackendEnvironment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
}

/// Configuration helper for different environments
class BackendConfig {
  /// Get configuration for development environment
  static Map<String, dynamic> development() {
    return {
      'environment': BackendEnvironment.development,
      'apiBaseUrl': 'http://localhost:4000',
      'debugMode': true,
      'timeout': 30,
    };
  }

  /// Get configuration for production environment
  static Map<String, dynamic> production() {
    return {
      'environment': BackendEnvironment.production,
      'apiBaseUrl': 'https://applink.fieldx.gr',
      'debugMode': false,
      'timeout': 15,
    };
  }

  /// Get configuration for staging environment
  static Map<String, dynamic> staging() {
    return {
      'environment': BackendEnvironment.staging,
      'apiBaseUrl': 'https://staging.fieldx.gr',
      'debugMode': true,
      'timeout': 20,
    };
  }
}