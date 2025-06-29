// lib/services/autopsy_service.dart - RENAMED & CLEANED
// Following FSM Architecture PLAN - Uses BackendService foundation

import 'dart:async';
import 'dart:developer' as developer;
import '../models/autopsy_models.dart';
import 'backend_service.dart';

/// Service for autopsy operations using Encore.ts backend
/// Handles autopsy CRUD operations with proper error handling
class AutopsyService {
  final BackendService _backend = BackendService.instance;

  AutopsyService() {
    developer.log('AutopsyService initialized', name: 'AutopsyService');
  }

  // ============= LIST OPERATIONS =============

  /// List autopsies with filtering and pagination
  Future<AutopsyResponse> listAutopsies(ListAutopsyParams params) async {
    try {
      developer.log('Listing autopsies with params: ${params.toJson()}', name: 'AutopsyService');
      
      final response = await _backend.get(
        '/autopsy/list', // Encore.ts endpoint pattern
        queryParameters: params.toJson()..removeWhere((key, value) => value == null),
      );

      final result = AutopsyResponse.fromJson(response.data);
      developer.log('Listed ${result.data.length} autopsies', name: 'AutopsyService');
      
      return result;
    } catch (error) {
      throw _handleError(error, 'Failed to list autopsies');
    }
  }

  /// Search autopsies by query
  Future<AutopsyResponse> searchAutopsies(SearchAutopsyParams params) async {
    try {
      developer.log('Searching autopsies: "${params.query}"', name: 'AutopsyService');
      
      final response = await _backend.get(
        '/autopsy/search', // Encore.ts endpoint pattern
        queryParameters: params.toJson()..removeWhere((key, value) => value == null),
      );

      final result = AutopsyResponse.fromJson(response.data);
      developer.log('Found ${result.data.length} autopsies', name: 'AutopsyService');
      
      return result;
    } catch (error) {
      throw _handleError(error, 'Failed to search autopsies');
    }
  }

  // ============= DETAIL OPERATIONS =============

  /// Get single autopsy by ID
  Future<SingleAutopsyResponse> getAutopsy(String id) async {
    try {
      developer.log('Getting autopsy: $id', name: 'AutopsyService');
      
      final response = await _backend.get('/autopsy/get/$id');
      
      final result = SingleAutopsyResponse.fromJson(response.data);
      developer.log('Retrieved autopsy: ${result.data?.id}', name: 'AutopsyService');
      
      return result;
    } catch (error) {
      throw _handleError(error, 'Failed to get autopsy');
    }
  }

  /// Create new autopsy
  Future<CAutopsy> createAutopsy(CreateAutopsyRequest request) async {
    try {
      developer.log('Creating autopsy: ${request.name}', name: 'AutopsyService');
      
      final response = await _backend.post(
        '/autopsy/create',
        data: request.toJson(),
      );

      final autopsy = CAutopsy.fromJson(response.data['data']);
      developer.log('Created autopsy: ${autopsy.id}', name: 'AutopsyService');
      
      return autopsy;
    } catch (error) {
      throw _handleError(error, 'Failed to create autopsy');
    }
  }

  /// Update existing autopsy
  Future<CAutopsy> updateAutopsy(String id, UpdateAutopsyRequest request) async {
    try {
      developer.log('Updating autopsy: $id', name: 'AutopsyService');
      
      final response = await _backend.put(
        '/autopsy/update/$id',
        data: request.toJson(),
      );

      final autopsy = CAutopsy.fromJson(response.data['data']);
      developer.log('Updated autopsy: ${autopsy.id}', name: 'AutopsyService');
      
      return autopsy;
    } catch (error) {
      throw _handleError(error, 'Failed to update autopsy');
    }
  }

  /// Delete autopsy (soft delete)
  Future<void> deleteAutopsy(String id) async {
    try {
      developer.log('Deleting autopsy: $id', name: 'AutopsyService');
      
      await _backend.delete('/autopsy/delete/$id');
      
      developer.log('Deleted autopsy: $id', name: 'AutopsyService');
    } catch (error) {
      throw _handleError(error, 'Failed to delete autopsy');
    }
  }

  /// Restore deleted autopsy
  Future<CAutopsy> restoreAutopsy(String id) async {
    try {
      developer.log('Restoring autopsy: $id', name: 'AutopsyService');
      
      final response = await _backend.post('/autopsy/restore/$id');
      
      final autopsy = CAutopsy.fromJson(response.data['data']);
      developer.log('Restored autopsy: ${autopsy.id}', name: 'AutopsyService');
      
      return autopsy;
    } catch (error) {
      throw _handleError(error, 'Failed to restore autopsy');
    }
  }

  // ============= PERMISSION OPERATIONS =============

  /// Get current user's autopsy permissions
  Future<AutopsyPermissions> getPermissions() async {
    try {
      developer.log('Getting autopsy permissions', name: 'AutopsyService');
      
      final response = await _backend.get('/autopsy/permissions');
      
      final permissions = AutopsyPermissions.fromJson(response.data['data']);
      developer.log('Retrieved permissions: canRead=${permissions.canRead}, canEdit=${permissions.canEdit}', name: 'AutopsyService');
      
      return permissions;
    } catch (error) {
      throw _handleError(error, 'Failed to get permissions');
    }
  }

  // ============= UTILITY METHODS =============

  /// Get status options for dropdowns
  List<AutopsyStatusOption> getStatusOptions() {
    return AutopsyOptions.statusOptions;
  }

  /// Get category options for dropdowns
  List<AutopsyCategoryOption> getCategoryOptions() {
    return AutopsyOptions.categoryOptions;
  }

  /// Get status label for display
  String getStatusLabel(String? status) {
    return AutopsyOptions.getStatusLabel(status) ?? status ?? 'Unknown';
  }

  /// Get category label for display
  String getCategoryLabel(String? category) {
    return AutopsyOptions.getCategoryLabel(category) ?? category ?? 'Unknown';
  }

  /// Get autopsy display name - ADDED for backward compatibility
  String getAutopsyDisplayName(CAutopsy autopsy) {
    if (autopsy.displayName?.isNotEmpty == true) {
      return autopsy.displayName!;
    }
    
    if (autopsy.autopsyCustomerName?.isNotEmpty == true) {
      return autopsy.autopsyCustomerName!;
    }
    
    if (autopsy.autopsyOrderNumber?.isNotEmpty == true) {
      return 'Order: ${autopsy.autopsyOrderNumber}';
    }
    
    return 'Autopsy ${autopsy.id}';
  }

  /// Get formatted address - ADDED for backward compatibility
  String? getFormattedAddress(CAutopsy autopsy) {
    final parts = <String>[];
    
    if (autopsy.address1?.isNotEmpty == true) parts.add(autopsy.address1!);
    if (autopsy.address2?.isNotEmpty == true) parts.add(autopsy.address2!);
    if (autopsy.city?.isNotEmpty == true) parts.add(autopsy.city!);
    if (autopsy.state?.isNotEmpty == true) parts.add(autopsy.state!);
    if (autopsy.postcode?.isNotEmpty == true) parts.add(autopsy.postcode!);
    if (autopsy.country?.isNotEmpty == true) parts.add(autopsy.country!);
    
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Format autopsy for display - now simplified
  Map<String, String> formatAutopsyForDisplay(CAutopsy autopsy) {
    return {
      'displayName': autopsy.effectiveDisplayName,
      'statusLabel': getStatusLabel(autopsy.autopsyStatus),
      'categoryLabel': getCategoryLabel(autopsy.autopsyCategory),
      'address': autopsy.fullAddress,
    };
  }

  // ============= ERROR HANDLING =============

  /// Handle and transform errors into appropriate exceptions
  Exception _handleError(dynamic error, String defaultMessage) {
    // If it's already a proper exception, return it
    if (error is AutopsyException) {
      return error;
    }

    // Log the error for debugging
    developer.log('AutopsyService error: $error', name: 'AutopsyService', error: error);

    // Handle Dio exceptions (from BackendService)
    if (error.toString().contains('404')) {
      return AutopsyNotFoundException(
        message: 'Autopsy not found',
        originalError: error,
      );
    } else if (error.toString().contains('403')) {
      return AutopsyPermissionException(
        message: 'Permission denied to access this autopsy',
        originalError: error,
      );
    } else if (error.toString().contains('401')) {
      return AutopsyPermissionException(
        message: 'Authentication required',
        originalError: error,
      );
    } else if (error.toString().contains('422')) {
      return AutopsyValidationException(
        message: 'Validation failed',
        originalError: error,
      );
    } else if (error.toString().contains('timeout') || 
               error.toString().contains('connection')) {
      return AutopsyNetworkException(
        message: 'Network error. Please check your connection.',
        originalError: error,
      );
    }

    // Default error
    return AutopsyException(
      message: defaultMessage,
      originalError: error,
    );
  }

  // ============= AUTHENTICATION INTEGRATION =============

  /// Set authentication token (delegates to BackendService)
  void setAuthToken(String token) {
    _backend.setAuthToken(token);
    developer.log('Auth token set for autopsy operations', name: 'AutopsyService');
  }

  /// Clear authentication token (delegates to BackendService)
  void clearAuthToken() {
    _backend.clearAuthToken();
    developer.log('Auth token cleared for autopsy operations', name: 'AutopsyService');
  }

  // ============= ENVIRONMENT MANAGEMENT =============

  /// Get current backend environment
  String get currentEnvironment => _backend.currentEnvironment;

  /// Get current API base URL
  String get currentApiUrl => _backend.getApiBaseUrl();
}

// For backward compatibility - alias the old class name
// Note: Use AutopsyService instead of AutopsyClient
typedef AutopsyClient = AutopsyService;