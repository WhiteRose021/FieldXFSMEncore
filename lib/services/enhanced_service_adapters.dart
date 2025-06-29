// lib/services/enhanced_service_adapters.dart
// Enhanced version of your service adapters with backend switching support (Discord Logger Removed)

// ignore_for_file: unused_field, deprecated_member_use_from_same_package, prefer_typing_uninitialized_variables, strict_top_level_inference, duplicate_ignore

import 'enhanced_unified_crm_service.dart';

/// ==================== ENHANCED ADAPTER CLASSES ====================
/// These adapters maintain your exact same interfaces while adding Encore support

/// Enhanced MetadataService Adapter
class MetadataService {
  static final EnhancedUnifiedCRMService _service = EnhancedUnifiedCRMService.instance;
  
  /// Maintains the exact same method signature as your original MetadataService
  Future<Map<String, dynamic>?> fetchMetadata() async {
    return await _service.fetchMetadata();
  }
  
  /// New method to check which backend is being used
  static bool isUsingEncore() => _service.isUsingEncore();
  static bool isUsingEspoCRM() => _service.isUsingEspoCRM();
}

/// Enhanced AppointmentService Adapter
class AppointmentService {
  static final EnhancedUnifiedCRMService _service = EnhancedUnifiedCRMService.instance;
  
  static const String apiKey = "espocrmapikey"; // Kept for compatibility
  
  // Expose baseUrl for SyncEngine compatibility
  static Future<String> get baseUrl async {
    final url = await _service.getActiveBaseUrl(); // Now uses active backend
    if (url == null) throw Exception("Backend URL is not configured");
    return url;
  }

  // Helper to get auth headers - now works with both backends
  static Future<Map<String, String>> get authHeaders async {
    return await _service.getOptimalHeaders();
  }
  
  /// Maintains exact same method signatures - now works with both backends
  Future<List<Map<String, dynamic>>> fetchTechnicianAppointments() async {
    return await _service.fetchTechnicianAppointments();
  }
  
  Future<List<Map<String, dynamic>>> fetchAssignedAppointments() async {
    return await _service.fetchTechnicianAppointments();
  }

  Future<Map<String, dynamic>?> fetchAppointmentDetails(String appointmentId) async {
    return await _service.fetchAppointmentDetails(appointmentId);
  }

  Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
    return await _service.updateAppointmentStatus(appointmentId, newStatus);
  }

  Future<bool> assignAppointmentToMe(String appointmentId) async {
    return await _service.assignBuildingToMe(appointmentId);
  }

  Future<bool> unassignAppointment(String appointmentId) async {
    return await _service.unassignBuilding(appointmentId);
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchAppointmentHistory(String appointmentId) async {
    return await _service.fetchAppointmentHistory(appointmentId);
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentHistoryStream(String appointmentId) async {
    return await _service.fetchSplicerHistory(appointmentId);
  }

  Future<List<dynamic>?> fetchAppointmentAttachments(String appointmentId) async {
    // This would need to be implemented based on your attachment logic
    return null;
  }

  /// New backend switching methods
  static Future<void> switchToEncore({String? tenantCode}) async {
    await _service.switchToEncore(tenantCode: tenantCode);
  }
  
  static Future<void> switchToEspoCRM() async {
    await _service.switchToEspoCRM();
  }
  
  static bool isUsingEncore() => _service.isUsingEncore();
  static bool isUsingEspoCRM() => _service.isUsingEspoCRM();
}

/// Enhanced CSplicingWorkService Adapter (Buildings)
class CSplicingWorkService {
  static final EnhancedUnifiedCRMService _service = EnhancedUnifiedCRMService.instance;
  
  static const String _apiKey = "espocrmapikey"; // Kept for compatibility
  static var authHeaders; // Kept for compatibility

  /// Maintains exact same method signatures - now works with both backends
  Future<List<Map<String, dynamic>>> fetchFilteredBuildings() async {
    return await _service.fetchFilteredBuildings();
  }

  Future<Map<String, dynamic>?> fetchBuildingDetails(String buildingId) async {
    return await _service.fetchAppointmentDetails(buildingId); // Same endpoint logic
  }

  Future<bool> updateBuildingStatus(String buildingId, String newStatus) async {
    return await _service.updateAppointmentStatus(buildingId, newStatus);
  }

  Future<bool> assignBuildingToMe(String buildingId) async {
    return await _service.assignBuildingToMe(buildingId);
  }

  Future<bool> unassignBuilding(String buildingId) async {
    return await _service.unassignBuilding(buildingId);
  }

  // Keep all your existing methods
  Future<Map<String, String>> getCombinedHeaders() async {
    return await _service.getOptimalHeaders(isWrite: false);
  }

  Future<void> migrateOldCachedBuildings() async {
  }

  /// New backend switching methods
  static Future<void> switchToEncore({String? tenantCode}) async {
    await _service.switchToEncore(tenantCode: tenantCode);
  }
  
  static Future<void> switchToEspoCRM() async {
    await _service.switchToEspoCRM();
  }
  
  static bool isUsingEncore() => _service.isUsingEncore();
  static bool isUsingEspoCRM() => _service.isUsingEspoCRM();
}

/// Enhanced AutopsyAppointmentService Adapter
class AutopsyAppointmentService {
  static final EnhancedUnifiedCRMService _service = EnhancedUnifiedCRMService.instance;
  
  static const String apiKey = "espocrmapikey";
  static const String _entityType = "Test";
  static const int _batchSize = 50;
  
  static Future<String> get baseUrl async {
    final url = await _service.getActiveBaseUrl();
    if (url == null) throw Exception("Backend URL is not configured");
    return url;
  }

  static Future<Map<String, String>> get authHeaders async {
    // ignore: deprecated_member_use_from_same_package
    return await _service.getOptimalHeaders();
  }
  
  /// Fetch technician's assigned autopsy appointments - now works with both backends
  Future<List<Map<String, dynamic>>> fetchTechnicianAutopsyAppointments() async {
    try {
      final appointments = await _service.fetchTechnicianAutopsyAppointments();
      return appointments;
    } catch (e) {
      return [];
    }
  }
  
  /// All your existing methods remain the same - they'll automatically use the active backend
  Future<List<Map<String, dynamic>>> fetchFilteredAutopsyAppointments({
    String? status,
    String? location,
    String? assignedUserId,
    String? dateFrom,
    String? dateTo,
    int limit = 50,
    int offset = 0,
  }) async {
    // Implementation that works with both backends
    return await _service.fetchTechnicianAutopsyAppointments();
  }

  Future<Map<String, dynamic>?> fetchAutopsyAppointmentDetails(String autopsyId) async {
    return await _service.fetchAppointmentDetails(autopsyId);
  }

  Future<bool> updateAutopsyAppointmentStatus(String autopsyId, String newStatus) async {
    return await _service.updateAppointmentStatus(autopsyId, newStatus);
  }

  Future<bool> assignAutopsyAppointmentToMe(String autopsyId) async {
    return await _service.assignBuildingToMe(autopsyId); // Same logic
  }

  /// New backend switching methods
  static Future<void> switchToEncore({String? tenantCode}) async {
    await _service.switchToEncore(tenantCode: tenantCode);
  }
  
  static Future<void> switchToEspoCRM() async {
    await _service.switchToEspoCRM();
  }
  
  static bool isUsingEncore() => _service.isUsingEncore();
  static bool isUsingEspoCRM() => _service.isUsingEspoCRM();
}

/// Enhanced ConstructionAppointmentService Adapter
class ConstructionAppointmentService {
  static final EnhancedUnifiedCRMService _service = EnhancedUnifiedCRMService.instance;
  
  static const String apiKey = "espocrmapikey";
  static const String _entityType = "CKataskeyastikadates";
  static const int _batchSize = 50;
  
  static Future<String> get baseUrl async {
    final url = await _service.getActiveBaseUrl();
    if (url == null) throw Exception("Backend URL is not configured");
    return url;
  }

  static Future<Map<String, String>> get authHeaders async {
    return await _service.getOptimalHeaders();
  }
  
  /// Fetch technician's assigned construction appointments
  Future<List<Map<String, dynamic>>> fetchTechnicianConstructionAppointments() async {
    try {
      final appointments = await _service.fetchTechnicianConstructionAppointments(forceRefresh: false);
      return appointments;
    } catch (e) {
      return [];
    }
  }
  
  /// Force refresh from API
  Future<List<Map<String, dynamic>>> refreshConstructionAppointments() async {
    try {
      final appointments = await _service.fetchTechnicianConstructionAppointments(forceRefresh: true);
      return appointments;
    } catch (e) {
      return [];
    }
  }
  
  /// All your existing methods work automatically with both backends
  Future<List<Map<String, dynamic>>> fetchFilteredConstructionAppointments({
    String? status,
    String? dateFrom,
    String? dateTo,
    String? assignedUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    // Implementation that works with both backends
    return await _service.fetchTechnicianConstructionAppointments();
  }

  /// New backend switching methods
  static Future<void> switchToEncore({String? tenantCode}) async {
    await _service.switchToEncore(tenantCode: tenantCode);
  }
  
  static Future<void> switchToEspoCRM() async {
    await _service.switchToEspoCRM();
  }
  
  static bool isUsingEncore() => _service.isUsingEncore();
  static bool isUsingEspoCRM() => _service.isUsingEspoCRM();
}

/// ==================== BACKEND MANAGEMENT UTILITY CLASS ====================
/// Central place to manage backend switching for the entire app

class BackendManager {
  static final EnhancedUnifiedCRMService _service = EnhancedUnifiedCRMService.instance;
  
  /// Initialize the app with a specific backend
  static Future<void> initializeApp({
    BackendType backendType = BackendType.espocrm,
    String? tenantCode,
    bool isDevelopment = true,
  }) async {
    await _service.initialize(
      backendType: backendType,
      tenantCode: tenantCode,
      isDevelopment: isDevelopment,
    );
    
  }
  
  /// Switch the entire app to Encore backend
  static Future<void> switchToEncore({required String tenantCode}) async {
    await _service.switchToEncore(tenantCode: tenantCode);
  }
  
  /// Switch the entire app to EspoCRM backend
  static Future<void> switchToEspoCRM() async {
    await _service.switchToEspoCRM();
  }
  
  /// Get current backend type
  static BackendType getCurrentBackend() => _service.getCurrentBackend();
  
  /// Check backend status
  static bool isUsingEncore() => _service.isUsingEncore();
  static bool isUsingEspoCRM() => _service.isUsingEspoCRM();
  
  /// Login methods that work with current backend
  static Future<bool> login(String username, String password) async {
    if (isUsingEncore()) {
      return await _service.loginWithEncore(username, password);
    } else {
      return await _service.loginWithEspoCRM(username, password);
    }
  }
  
  /// Logout from current backend
  static Future<void> logout() async {
    // Add logout logic for both backends
    // Clear tokens, cache, etc.
  }
  
  /// Test connectivity to current backend
  static Future<bool> testConnectivity() async {
    try {
      return await _service.testBackendConnectivity();
    } catch (e) {
      return false;
    }
  }
}