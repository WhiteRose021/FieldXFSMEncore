// lib/services/permissions_manager.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/autopsy_models.dart';
import '../services/autopsy_client.dart';

/// Field-level permission information
class FieldPermission {
  final String fieldName;
  final bool canRead;
  final bool canEdit;
  final String? reason;

  const FieldPermission({
    required this.fieldName,
    required this.canRead,
    required this.canEdit,
    this.reason,
  });

  bool get isVisible => canRead;
  bool get isEditable => canRead && canEdit;
  bool get isReadOnly => canRead && !canEdit;
  bool get isHidden => !canRead;
}

/// Permission summary for debugging and UI
class PermissionSummary {
  final String entityType;
  final AutopsyPermissions entityPermissions;
  final Map<String, FieldPermission> fieldPermissions;
  final DateTime loadedAt;

  PermissionSummary({
    required this.entityType,
    required this.entityPermissions,
    required this.fieldPermissions,
    required this.loadedAt,
  });

  // Field collections
  List<String> get visibleFields => fieldPermissions.entries
      .where((e) => e.value.canRead)
      .map((e) => e.key)
      .toList();

  List<String> get editableFields => fieldPermissions.entries
      .where((e) => e.value.canRead && e.value.canEdit)
      .map((e) => e.key)
      .toList();

  List<String> get readOnlyFields => fieldPermissions.entries
      .where((e) => e.value.canRead && !e.value.canEdit)
      .map((e) => e.key)
      .toList();

  List<String> get hiddenFields => fieldPermissions.entries
      .where((e) => !e.value.canRead)
      .map((e) => e.key)
      .toList();

  // Statistics
  int get totalFields => fieldPermissions.length;
  int get visibleFieldCount => visibleFields.length;
  int get editableFieldCount => editableFields.length;
  int get readOnlyFieldCount => readOnlyFields.length;
  int get hiddenFieldCount => hiddenFields.length;

  Map<String, dynamic> toDebugMap() {
    return {
      'entityType': entityType,
      'loadedAt': loadedAt.toIso8601String(),
      'entityPermissions': {
        'canCreate': entityPermissions.canCreate,
        'canRead': entityPermissions.canRead,
        'canEdit': entityPermissions.canEdit,
        'canDelete': entityPermissions.canDelete,
        'canRestore': entityPermissions.canRestore,
        'canPermanentDelete': entityPermissions.canPermanentDelete,
        'canViewDeleted': entityPermissions.canViewDeleted,
      },
      'fieldStats': {
        'total': totalFields,
        'visible': visibleFieldCount,
        'editable': editableFieldCount,
        'readOnly': readOnlyFieldCount,
        'hidden': hiddenFieldCount,
      },
      'visibleFields': visibleFields,
      'editableFields': editableFields,
      'readOnlyFields': readOnlyFields,
      'hiddenFields': hiddenFields,
    };
  }
}

/// Manages permissions for the autopsy system
class PermissionsManager extends ChangeNotifier {
  final AutopsyClient _client;
  
  PermissionSummary? _permissionSummary;
  bool _isLoading = false;
  String? _error;
  
  // Cache settings
  final Duration _cacheTimeout = const Duration(minutes: 10);
  
  // Commonly used field names for autopsy entity
  static const List<String> _commonFields = [
    'id',
    'name',
    'description',
    'created_at',
    'modified_at',
    'assigned_user_id',
    'autopsyfulladdress',
    'autopsystreet',
    'autopsypostalcode',
    'autopsymunicipality',
    'autopsystate',
    'autopsycity',
    'autopsycustomername',
    'autopsycustomeremail',
    'autopsycustomermobile',
    'autopsylandlinephonenumber',
    'autopsystatus',
    'autopsycategory',
    'autopsycomments',
    'technicalcheckstatus',
    'soilworkstatus',
    'constructionstatus',
    'splicingstatus',
    'billingstatus',
    'malfunctionstatus',
    'autopsylatitude',
    'autopsylongtitude',
    'autopsyordernumber',
    'autopsybid',
    'autopsycab',
    'autopsyage',
    'autopsyak',
    'autopsyadminemail',
    'autopsyadminmobile',
    'autopsyadminlandline',
    'autopsyoutofsystem',
    'autopsycustomerfloor',
    'autopsypilot',
    'autopsyttlp',
    'autopsyttllppptest',
    'building_id',
    'type',
    'adminautopsyname',
  ];

  PermissionsManager({required AutopsyClient client}) : _client = client;

  // ============= GETTERS =============

  PermissionSummary? get permissionSummary => _permissionSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermissions => _permissionSummary != null;
  bool get isStale => _permissionSummary == null || 
      DateTime.now().difference(_permissionSummary!.loadedAt) > _cacheTimeout;
  
  AutopsyPermissions? get entityPermissions => _permissionSummary?.entityPermissions;
  
  // Entity-level permission getters
  bool get canCreate => _permissionSummary?.entityPermissions.canCreate ?? false;
  bool get canRead => _permissionSummary?.entityPermissions.canRead ?? true;
  bool get canEdit => _permissionSummary?.entityPermissions.canEdit ?? false;
  bool get canDelete => _permissionSummary?.entityPermissions.canDelete ?? false;
  bool get canRestore => _permissionSummary?.entityPermissions.canRestore ?? false;
  bool get canPermanentDelete => _permissionSummary?.entityPermissions.canPermanentDelete ?? false;
  bool get canViewDeleted => _permissionSummary?.entityPermissions.canViewDeleted ?? false;

  // Quick access to field collections
  List<String> get visibleFields => _permissionSummary?.visibleFields ?? [];
  List<String> get editableFields => _permissionSummary?.editableFields ?? [];
  List<String> get readOnlyFields => _permissionSummary?.readOnlyFields ?? [];
  List<String> get hiddenFields => _permissionSummary?.hiddenFields ?? [];

  // ============= PERMISSION LOADING =============

  /// Load permissions for the autopsy entity
  Future<void> loadPermissions() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log('🔐 Loading autopsy permissions...');
      
      final permissions = await _client.getPermissions();
      final fieldPermissions = _generateFieldPermissions(permissions);
      
      _permissionSummary = PermissionSummary(
        entityType: 'autopsy',
        entityPermissions: permissions,
        fieldPermissions: fieldPermissions,
        loadedAt: DateTime.now(),
      );
      
      developer.log('✅ Permissions loaded successfully');
      
    } catch (error) {
      _error = error.toString();
      developer.log('❌ Failed to load permissions: $error');
      
      // Fallback to default permissions
      _permissionSummary = PermissionSummary(
        entityType: 'autopsy',
        entityPermissions: AutopsyPermissions.defaultPermissions(),
        fieldPermissions: {},
        loadedAt: DateTime.now(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear permission cache
  Future<void> clearCache() async {
    try {
      await _client.clearPermissionCache();
      _permissionSummary = null;
      _error = null;
      notifyListeners();
      developer.log('🧽 Permission cache cleared');
    } catch (error) {
      developer.log('⚠️ Failed to clear permission cache: $error');
    }
  }

  // ============= FIELD-LEVEL PERMISSION CHECKS =============

  /// Check if a field can be read/viewed
  bool canReadField(String fieldName) {
    final fieldPermission = _permissionSummary?.fieldPermissions[fieldName];
    return fieldPermission?.canRead ?? true; // Default to visible
  }

  /// Check if a field can be edited
  bool canEditField(String fieldName) {
    final fieldPermission = _permissionSummary?.fieldPermissions[fieldName];
    return fieldPermission?.isEditable ?? false; // Default to not editable
  }

  /// LEGACY METHOD NAMES for backward compatibility
  bool isFieldVisible(String fieldName) => canReadField(fieldName);
  bool isFieldEditable(String fieldName) => canEditField(fieldName);

  /// Get field permission details
  FieldPermission? getFieldPermission(String fieldName) {
    return _permissionSummary?.fieldPermissions[fieldName];
  }

  /// Check multiple fields at once
  Map<String, FieldPermission> checkMultipleFields(List<String> fieldNames) {
    final results = <String, FieldPermission>{};
    
    for (final fieldName in fieldNames) {
      final canRead = canReadField(fieldName);
      final canEdit = canEditField(fieldName);
      
      final permission = _permissionSummary?.fieldPermissions[fieldName] ??
          FieldPermission(
            fieldName: fieldName,
            canRead: canRead,
            canEdit: canEdit,
            reason: 'Inherited from entity permissions',
          );
      results[fieldName] = permission;
    }
    
    return results;
  }

  /// Get all permissions for common autopsy fields
  Map<String, FieldPermission> getAllFieldPermissions() {
    return checkMultipleFields(_commonFields);
  }

  // ============= PERMISSION FILTERING =============

  /// Filter a map of values based on field visibility
  Map<String, T> filterVisibleFields<T>(Map<String, T> fields) {
    final filtered = <String, T>{};
    
    for (final entry in fields.entries) {
      if (canReadField(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    
    return filtered;
  }

  /// Filter a map of values based on field editability
  Map<String, T> filterEditableFields<T>(Map<String, T> fields) {
    final filtered = <String, T>{};
    
    for (final entry in fields.entries) {
      if (canEditField(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    
    return filtered;
  }

  /// Get visible fields from an autopsy object
  Map<String, dynamic> getVisibleAutopsyFields(CAutopsy autopsy) {
    final autopsyJson = autopsy.toJson();
    return filterVisibleFields(autopsyJson);
  }

  /// Get editable fields from a request object
  Map<String, dynamic> filterEditableUpdateFields(Map<String, dynamic> updateData) {
    return filterEditableFields(updateData);
  }

  // ============= ACTION PERMISSION CHECKING =============

  /// Check if user can perform a specific action
  bool canPerformAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return canCreate;
      case 'read':
      case 'view':
        return canRead;
      case 'edit':
      case 'update':
        return canEdit;
      case 'delete':
        return canDelete;
      case 'restore':
        return canRestore;
      case 'permanent_delete':
        return canPermanentDelete;
      case 'view_deleted':
        return canViewDeleted;
      default:
        return false;
    }
  }

  // ============= DEBUGGING =============

  /// Get debug summary of permissions
  Map<String, dynamic> getDebugSummary() {
    if (_permissionSummary == null) {
      return {
        'status': 'No permissions loaded',
        'isLoading': _isLoading,
        'error': _error,
      };
    }

    return _permissionSummary!.toDebugMap();
  }

  /// Print debug information
  void printDebugInfo() {
    final debug = getDebugSummary();
    developer.log('🔐 Permissions Debug:\n${debug.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}');
  }

  // ============= PRIVATE HELPERS =============

  /// Generate field permissions based on entity permissions
  Map<String, FieldPermission> _generateFieldPermissions(AutopsyPermissions entityPermissions) {
    final Map<String, FieldPermission> fieldPermissions = {};

    // Process visible fields
    for (final fieldName in entityPermissions.visibleFields) {
      final canEdit = entityPermissions.editableFields.contains(fieldName);
      fieldPermissions[fieldName] = FieldPermission(
        fieldName: fieldName,
        canRead: true,
        canEdit: canEdit,
        reason: 'Explicitly listed in visible fields',
      );
    }

    // Process editable fields (ensure they're also readable)
    for (final fieldName in entityPermissions.editableFields) {
      if (!fieldPermissions.containsKey(fieldName)) {
        fieldPermissions[fieldName] = FieldPermission(
          fieldName: fieldName,
          canRead: true,
          canEdit: true,
          reason: 'Explicitly listed in editable fields',
        );
      }
    }

    // Add common fields with default permissions if not specified
    for (final fieldName in _commonFields) {
      if (!fieldPermissions.containsKey(fieldName)) {
        // If visible fields is empty, assume all common fields are visible
        final defaultVisible = entityPermissions.visibleFields.isEmpty;
        final defaultEditable = entityPermissions.editableFields.contains(fieldName);
        
        fieldPermissions[fieldName] = FieldPermission(
          fieldName: fieldName,
          canRead: defaultVisible,
          canEdit: defaultEditable && entityPermissions.canEdit,
          reason: 'Default permission for common field',
        );
      }
    }

    return fieldPermissions;
  }
}