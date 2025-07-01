// lib/services/permissions_manager.dart - ENHANCED VERSION
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/autopsy_models.dart';
import 'backend_service.dart';
import 'auth_service.dart';

class PermissionsManager extends ChangeNotifier {
  AutopsyPermissions? _permissions;
  bool _isLoading = false;
  String? _error;
  final Map<String, dynamic> _cache = {};
  
  // Cache management
  static const String _permissionsCacheKey = 'autopsy_permissions_cache';
  static const String _permissionsCacheTimestampKey = 'permissions_cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 1);

  // Current user context for permission validation
  String? _currentUserId;
  String? _currentTenantId;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;

  // Getters
  AutopsyPermissions? get permissions => _permissions;
  bool get hasPermissions => _permissions != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Permission shortcuts
  bool get canCreate => _permissions?.canCreate ?? false;
  bool get canEdit => _permissions?.canEdit ?? false;
  bool get canDelete => _permissions?.canDelete ?? false;
  bool get canRestore => _permissions?.canRestore ?? false;
  bool get canViewDeleted => _permissions?.canViewDeleted ?? false;

  /// Initialize permissions for authenticated user
  Future<void> initializeUserPermissions(AuthService authService) async {
    if (!authService.isAuthenticated) {
      debugPrint('⚠️ Cannot initialize permissions: User not authenticated');
      return;
    }

    _currentUserId = authService.userId;
    _currentTenantId = authService.tenantName;
    _isAdmin = authService.userType?.toLowerCase() == 'admin';
    _isSuperAdmin = authService.currentUser?.toLowerCase() == 'superadmin' && _isAdmin;

    debugPrint('🔐 Initializing permissions for user: $_currentUserId, tenant: $_currentTenantId');
    debugPrint('👤 User type: ${authService.userType}, isAdmin: $_isAdmin, isSuperAdmin: $_isSuperAdmin');

    await loadPermissions();
  }

  /// Load permissions from Encore backend
  Future<void> loadPermissions() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('📋 Loading permissions from cache first...');
      
      // Try cache first
      final cachedPermissions = await _loadPermissionsFromCache();
      if (cachedPermissions != null) {
        _permissions = cachedPermissions;
        notifyListeners();
        debugPrint('✅ Loaded permissions from cache');
        
        // Refresh in background
        _refreshPermissionsInBackground();
        return;
      }

      // Load fresh permissions from backend
      await _loadFreshPermissions();

    } catch (error) {
      debugPrint('❌ Error loading permissions: $error');
      _error = error.toString();
      _permissions = AutopsyPermissions.defaultPermissions;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load fresh permissions from Encore backend
  Future<void> _loadFreshPermissions() async {
    try {
      debugPrint('🌐 Loading fresh permissions from Encore backend...');

      // Call your Encore backend permission endpoint
      final response = await BackendService.instance.get('/metadata/permissions/c_autopsy');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        debugPrint('📋 Raw permission data: $data');

        // Transform Encore permission data to your AutopsyPermissions model
        _permissions = _transformEncorePermissions(data);
        
        // Cache the permissions
        await _cachePermissions(_permissions!);
        
        debugPrint('✅ Permissions loaded and cached successfully');
        debugPrint('🔑 User can: create=${_permissions!.canCreate}, edit=${_permissions!.canEdit}, delete=${_permissions!.canDelete}');
        
      } else {
        throw Exception('Failed to load permissions: ${response.statusCode}');
      }

    } catch (error) {
      debugPrint('❌ Error loading fresh permissions: $error');
      rethrow;
    }
  }

  /// Transform Encore backend permission data to AutopsyPermissions model
  AutopsyPermissions _transformEncorePermissions(Map<String, dynamic> data) {
    try {
      // Extract entity permissions from Encore response
      final entityPermissions = data['entityPermissions'] ?? {};
      final fieldPermissions = data['fieldPermissions'] ?? {};
      final userContext = data['userContext'] ?? {};
      
      debugPrint('🔍 Entity permissions: $entityPermissions');
      debugPrint('📝 Field permissions: $fieldPermissions');
      debugPrint('👤 User context: $userContext');

      // Map Encore permission levels to boolean permissions
      final createPermission = entityPermissions['create'] ?? 'no';
      final readPermission = entityPermissions['read'] ?? 'no';
      final editPermission = entityPermissions['edit'] ?? 'no';
      final deletePermission = entityPermissions['delete'] ?? 'no';

      // Super admin and admin users get all permissions
      final isUserAdmin = userContext['isAdmin'] == true || userContext['isSuperAdmin'] == true;
      
      // Build visible fields list
      final visibleFields = <String>[];
      final editableFields = <String>[];
      final creatableFields = <String>[];
      
      // Process field permissions
      if (fieldPermissions is Map) {
        fieldPermissions.forEach((fieldName, fieldPerms) {
          if (fieldPerms is Map) {
            // Check field visibility
            final canRead = fieldPerms['read'] != 'no';
            final canEdit = fieldPerms['edit'] != 'no';
            
            if (canRead || isUserAdmin) {
              visibleFields.add(fieldName);
            }
            
            if (canEdit || isUserAdmin) {
              editableFields.add(fieldName);
              creatableFields.add(fieldName); // If can edit, can also create
            }
          }
        });
      }

      // If no specific field permissions, add default fields
      if (visibleFields.isEmpty) {
        visibleFields.addAll([
          'name', 'description', 'autopsyStatus', 'autopsyComments', 
          'autopsyCustomerName', 'autopsyFullAddress', 'createdAt'
        ]);
      }

      if (editableFields.isEmpty && (editPermission != 'no' || isUserAdmin)) {
        editableFields.addAll([
          'name', 'autopsyStatus', 'autopsyComments', 'autopsyCustomerName', 'autopsyFullAddress'
        ]);
      }

      if (creatableFields.isEmpty && (createPermission != 'no' || isUserAdmin)) {
        creatableFields.addAll([
          'name', 'description', 'autopsyStatus', 'autopsyComments', 
          'autopsyCustomerName', 'autopsyFullAddress'
        ]);
      }

      return AutopsyPermissions(
        canRead: readPermission != 'no' || isUserAdmin,
        canCreate: createPermission != 'no' || isUserAdmin,
        canEdit: editPermission != 'no' || isUserAdmin,
        canDelete: deletePermission != 'no' || isUserAdmin,
        canRestore: deletePermission != 'no' || isUserAdmin, // Same as delete for now
        canPermanentDelete: isUserAdmin, // Only admin can permanently delete
        canViewDeleted: editPermission != 'no' || isUserAdmin,
        visibleFields: visibleFields,
        editableFields: editableFields,
        creatableFields: creatableFields,
      );

    } catch (error) {
      debugPrint('❌ Error transforming permissions: $error');
      return AutopsyPermissions.defaultPermissions;
    }
  }

  /// Check if user can edit specific record (record-level permissions)
  bool canEditRecord(Map<String, dynamic> record) {
    if (_permissions == null) return false;
    
    // Super admin can edit everything
    if (_isSuperAdmin) return true;
    
    // Admin can edit everything in their tenant
    if (_isAdmin) return true;
    
    // If user has no edit permission at all
    if (!_permissions!.canEdit) return false;

    // For regular users, check if they own the record
    final assignedUserId = record['assigned_user_id'] ?? record['assignedUserId'];
    final createdById = record['created_by_id'] ?? record['createdById'];
    
    return assignedUserId == _currentUserId || createdById == _currentUserId;
  }

  /// Check if user can delete specific record
  bool canDeleteRecord(Map<String, dynamic> record) {
    if (_permissions == null) return false;
    
    // Super admin can delete everything
    if (_isSuperAdmin) return true;
    
    // Admin can delete everything in their tenant
    if (_isAdmin) return true;
    
    // If user has no delete permission at all
    if (!_permissions!.canDelete) return false;

    // For regular users, check if they own the record
    final assignedUserId = record['assigned_user_id'] ?? record['assignedUserId'];
    final createdById = record['created_by_id'] ?? record['createdById'];
    
    return assignedUserId == _currentUserId || createdById == _currentUserId;
  }

  /// Get query parameters for API calls based on user permissions
  Map<String, dynamic> getUserQueryParameters() {
    final params = <String, dynamic>{};
    
    // For non-admin users, add team filter
    if (!_isAdmin && !_isSuperAdmin) {
      params['teamFilter'] = 'team'; // Let backend handle the filtering
    }

    return params;
  }

  /// Refresh permissions in background
  void _refreshPermissionsInBackground() {
    Future.microtask(() async {
      try {
        await _loadFreshPermissions();
      } catch (e) {
        debugPrint('⚠️ Background permission refresh failed: $e');
      }
    });
  }

  /// Cache permissions locally
  Future<void> _cachePermissions(AutopsyPermissions permissions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionData = permissions.toJson();
      
      await prefs.setString(_permissionsCacheKey, json.encode(permissionData));
      await prefs.setInt(_permissionsCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('💾 Permissions cached successfully');
    } catch (e) {
      debugPrint('❌ Error caching permissions: $e');
    }
  }

  /// Load permissions from cache if valid
  Future<AutopsyPermissions?> _loadPermissionsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_permissionsCacheKey);
      final cacheTimestamp = prefs.getInt(_permissionsCacheTimestampKey);

      if (cachedData != null && cacheTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
        if (cacheAge < _cacheExpiry.inMilliseconds) {
          final permissionData = json.decode(cachedData) as Map<String, dynamic>;
          return AutopsyPermissions.fromJson(permissionData);
        } else {
          debugPrint('📋 Permission cache expired, will refresh');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading cached permissions: $e');
    }
    return null;
  }

  /// Clear permissions and cache (on logout)
  void clearPermissions() {
    _permissions = null;
    _error = null;
    _currentUserId = null;
    _currentTenantId = null;
    _isAdmin = false;
    _isSuperAdmin = false;
    _clearCache();
    notifyListeners();
    debugPrint('🗑️ Permissions cleared');
  }

  /// Clear cache method (required by SettingsScreen)
  void clearCache() {
    _clearCache();
    _permissions = null;
    _error = null;
    notifyListeners();
    debugPrint('🗑️ Permission cache cleared');
  }

  /// Internal cache clearing
  Future<void> _clearCache() async {
    try {
      _cache.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_permissionsCacheKey);
      await prefs.remove(_permissionsCacheTimestampKey);
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Force refresh permissions from server
  Future<void> refreshPermissions() async {
    debugPrint('🔄 Force refreshing permissions...');
    _permissions = null;
    await _clearCache();
    await loadPermissions();
  }

  /// Get debug summary (required by SettingsScreen)
  Map<String, dynamic> getDebugSummary() {
    return {
      'Has Permissions': hasPermissions,
      'Is Loading': isLoading,
      'Error': error ?? 'None',
      'Current User ID': _currentUserId ?? 'None',
      'Current Tenant ID': _currentTenantId ?? 'None',
      'Is Admin': _isAdmin,
      'Is Super Admin': _isSuperAdmin,
      'Can Create': canCreate,
      'Can Edit': canEdit,
      'Can Delete': canDelete,
      'Can Restore': canRestore,
      'Can View Deleted': canViewDeleted,
      'Visible Fields': _permissions?.visibleFields.length ?? 0,
      'Editable Fields': _permissions?.editableFields.length ?? 0,
      'Creatable Fields': _permissions?.creatableFields.length ?? 0,
      'Cache Size': _cache.length,
      'Last Updated': DateTime.now().toIso8601String(),
    };
  }

  // EXISTING METHODS (keep compatibility with current code)

  /// Check if a specific field can be edited (required by AutopsyEditBottomSheet)
  bool canEditField(String fieldName) {
    if (_permissions == null) return false;
    return _permissions!.editableFields.contains(fieldName);
  }

  /// Check if a specific field is visible
  bool canViewField(String fieldName) {
    if (_permissions == null) return false;
    return _permissions!.visibleFields.isEmpty || _permissions!.visibleFields.contains(fieldName);
  }

  /// Check if a specific field can be created
  bool canCreateField(String fieldName) {
    if (_permissions == null) return false;
    return _permissions!.creatableFields.contains(fieldName);
  }

  /// Get all visible fields
  List<String> getVisibleFields() {
    return _permissions?.visibleFields ?? [];
  }

  /// Get all editable fields
  List<String> getEditableFields() {
    return _permissions?.editableFields ?? [];
  }

  /// Get all creatable fields
  List<String> getCreatableFields() {
    return _permissions?.creatableFields ?? [];
  }

  /// Check if user can perform specific action
  bool canPerformAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return canCreate;
      case 'edit':
      case 'update':
        return canEdit;
      case 'delete':
        return canDelete;
      case 'restore':
        return canRestore;
      case 'view_deleted':
        return canViewDeleted;
      default:
        return false;
    }
  }

  // Cache management methods (keep for compatibility)
  void setCacheValue(String key, dynamic value) {
    _cache[key] = value;
  }

  T? getCacheValue<T>(String key) {
    return _cache[key] as T?;
  }

  bool hasCacheValue(String key) {
    return _cache.containsKey(key);
  }
}