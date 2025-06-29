// lib/services/enhanced_autopsy_client.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/autopsy_models.dart';

class EnhancedAutopsyClient {
  static EnhancedAutopsyClient? _instance;
  static EnhancedAutopsyClient get instance => _instance ??= EnhancedAutopsyClient._internal();

  late final Dio _dio;
  final Duration _defaultTimeout = const Duration(seconds: 30);
  
  // Private constructor
  EnhancedAutopsyClient._internal();

  void initialize(String baseUrl, {Map<String, dynamic>? defaultHeaders}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _defaultTimeout,
      receiveTimeout: _defaultTimeout,
      sendTimeout: _defaultTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?defaultHeaders,
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => developer.log(object.toString(), name: 'EnhancedAutopsyClient'),
      ));
    }

    // Error handling interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final customError = _handleDioError(error);
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: customError,
          type: error.type,
          response: error.response,
        ));
      },
    ));
  }

  // ============= LIST OPERATIONS =============

  Future<AutopsyListResponse> listAutopsies({
    int? limit,
    int? offset,
    String? search,
    String? status,
    String? category,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (orderBy != null) queryParams['orderBy'] = orderBy;
      if (orderDirection != null) queryParams['orderDirection'] = orderDirection;

      final response = await _dio.get(
        '/api/autopsies',
        queryParameters: queryParams,
      );

      return AutopsyListResponse.fromJson(response.data);
    } catch (error) {
      throw _handleError(error, 'Failed to list autopsies');
    }
  }

  Future<AutopsyListResponse> searchAutopsies(String query, {int? limit, int? offset}) async {
    try {
      final queryParams = <String, dynamic>{
        'query': query,
      };
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/api/autopsies/search',
        queryParameters: queryParams,
      );

      return AutopsyListResponse.fromJson(response.data);
    } catch (error) {
      throw _handleError(error, 'Failed to search autopsies');
    }
  }

  // ============= DETAIL OPERATIONS =============

  Future<AutopsyDetailResponse> getAutopsy(String id) async {
    try {
      final response = await _dio.get('/api/autopsies/$id');
      return AutopsyDetailResponse.fromJson(response.data);
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 404) {
        throw AutopsyNotFoundException(message: 'Autopsy not found');
      } else if (error is DioException && error.response?.statusCode == 403) {
        throw AutopsyPermissionException(message: 'Permission denied to view this autopsy');
      }
      throw _handleError(error, 'Failed to get autopsy');
    }
  }

  Future<AutopsyDetailResponse> createAutopsy(CreateAutopsyRequest request) async {
    try {
      final response = await _dio.post(
        '/api/autopsies',
        data: request.toJson(),
      );

      return AutopsyDetailResponse.fromJson(response.data);
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 422) {
        throw AutopsyValidationException(
          message: 'Validation failed',
          originalError: error,
        );
      } else if (error is DioException && error.response?.statusCode == 403) {
        throw AutopsyPermissionException(
          message: 'Permission denied to create autopsy',
        );
      }
      throw _handleError(error, 'Failed to create autopsy');
    }
  }

  Future<AutopsyDetailResponse> updateAutopsy(String id, UpdateAutopsyRequest request) async {
    try {
      final response = await _dio.put(
        '/api/autopsies/$id',
        data: request.toJson(),
      );

      return AutopsyDetailResponse.fromJson(response.data);
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 422) {
        throw AutopsyValidationException(
          message: 'Validation failed',
          originalError: error,
        );
      } else if (error is DioException && error.response?.statusCode == 403) {
        throw AutopsyPermissionException(
          message: 'Permission denied to update autopsy',
        );
      } else if (error is DioException && error.response?.statusCode == 404) {
        throw AutopsyNotFoundException(
          message: 'Autopsy not found',
        );
      }
      throw _handleError(error, 'Failed to update autopsy');
    }
  }

  Future<void> deleteAutopsy(String id) async {
    try {
      await _dio.delete('/api/autopsies/$id');
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 403) {
        throw AutopsyPermissionException(
          message: 'Permission denied to delete autopsy',
        );
      } else if (error is DioException && error.response?.statusCode == 404) {
        throw AutopsyNotFoundException(
          message: 'Autopsy not found',
        );
      }
      throw _handleError(error, 'Failed to delete autopsy');
    }
  }

  Future<AutopsyDetailResponse> restoreAutopsy(String id) async {
    try {
      final response = await _dio.post('/api/autopsies/$id/restore');
      return AutopsyDetailResponse.fromJson(response.data);
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 403) {
        throw AutopsyPermissionException(
          message: 'Permission denied to restore autopsy',
        );
      } else if (error is DioException && error.response?.statusCode == 404) {
        throw AutopsyNotFoundException(
          message: 'Autopsy not found',
        );
      }
      throw _handleError(error, 'Failed to restore autopsy');
    }
  }

  // ============= PERMISSION OPERATIONS =============

  Future<PermissionResponse> getPermissions() async {
    try {
      final response = await _dio.get('/api/autopsies/permissions');
      return PermissionResponse.fromJson(response.data);
    } catch (error) {
      throw _handleError(error, 'Failed to get permissions');
    }
  }

  // ============= UTILITY METHODS =============

  List<AutopsyStatusOption> getStatusOptions() {
    return AutopsyOptions.statusOptions;
  }

  List<AutopsyCategoryOption> getCategoryOptions() {
    return AutopsyOptions.categoryOptions;
  }

  String getStatusLabel(String? status) {
    return AutopsyOptions.getStatusLabel(status) ?? status ?? 'Unknown';
  }

  String getCategoryLabel(String? category) {
    return AutopsyOptions.getCategoryLabel(category) ?? category ?? 'Unknown';
  }

  String getAutopsyDisplayName(CAutopsy autopsy) {
    return autopsy.effectiveDisplayName;
  }

  String? getFormattedAddress(CAutopsy autopsy) {
    return autopsy.fullAddress.isEmpty ? null : autopsy.fullAddress;
  }

  // ============= AUTHENTICATION =============

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ============= ERROR HANDLING =============

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AutopsyNetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          return AutopsyPermissionException(
            message: 'Authentication required',
            originalError: error,
          );
        } else if (statusCode == 403) {
          return AutopsyPermissionException(
            message: 'Permission denied',
            originalError: error,
          );
        } else if (statusCode == 404) {
          return AutopsyNotFoundException(
            message: 'Resource not found',
            originalError: error,
          );
        } else if (statusCode == 422 && data is Map) {
          // Validation errors
          final fieldErrors = <String, List<String>>{};
          if (data['errors'] is Map) {
            final errors = data['errors'] as Map<String, dynamic>;
            for (final entry in errors.entries) {
              if (entry.value is List) {
                fieldErrors[entry.key] = List<String>.from(entry.value);
              } else if (entry.value is String) {
                fieldErrors[entry.key] = [entry.value];
              }
            }
          }
          
          return AutopsyValidationException(
            message: data['message'] ?? 'Validation failed',
            fieldErrors: fieldErrors,
            originalError: error,
          );
        } else {
          String message = 'Server error';
          if (data is Map && data['message'] is String) {
            message = data['message'];
          }
          
          return AutopsyNetworkException(
            message: message,
            statusCode: statusCode,
            originalError: error,
          );
        }

      case DioExceptionType.connectionError:
        return AutopsyNetworkException(
          message: 'No internet connection. Please check your network settings.',
          originalError: error,
        );

      case DioExceptionType.cancel:
        return AutopsyException(
          message: 'Request was cancelled',
          originalError: error,
        );

      default:
        return AutopsyException(
          message: 'An unexpected error occurred',
          originalError: error,
        );
    }
  }

  Exception _handleError(dynamic error, String defaultMessage) {
    if (error is AutopsyException) {
      return error;
    } else if (error is DioException) {
      return _handleDioError(error);
    } else {
      return AutopsyException(
        message: defaultMessage,
        originalError: error,
      );
    }
  }

  // ============= DISPOSAL =============

  void dispose() {
    _dio.close();
  }
}