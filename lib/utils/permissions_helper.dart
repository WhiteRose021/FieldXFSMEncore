// lib/utils/permissions_helper.dart
import 'dart:developer' as developer;
import '../services/permissions_manager.dart';

class PermissionsHelper {
  /// Ensures that permissions are loaded and cached in the PermissionsManager
  static Future<void> ensurePermissionsLoaded(PermissionsManager manager) async {
    try {
      developer.log('🔐 Ensuring permissions are loaded...', name: 'PermissionsHelper');
      
      // Check if permissions are already loaded and not stale
      if (manager.hasPermissions && !manager.isStale) {
        developer.log('✅ Permissions already loaded and valid', name: 'PermissionsHelper');
        return;
      }
      
      // Load permissions
      await manager.loadPermissions();
      developer.log('✅ Permissions loaded successfully', name: 'PermissionsHelper');
      
    } catch (error) {
      developer.log('❌ Failed to load permissions: $error', name: 'PermissionsHelper');
      rethrow;
    }
  }

  /// Refreshes permissions from the server
  static Future<void> refreshPermissions(PermissionsManager manager) async {
    try {
      developer.log('🔄 Refreshing permissions...', name: 'PermissionsHelper');
      await manager.clearCache();
      await manager.loadPermissions();
      developer.log('✅ Permissions refreshed successfully', name: 'PermissionsHelper');
    } catch (error) {
      developer.log('❌ Failed to refresh permissions: $error', name: 'PermissionsHelper');
      rethrow;
    }
  }

  /// Checks if a specific permission is granted
  static bool hasPermission(PermissionsManager manager, String permission) {
    return manager.canPerformAction(permission);
  }

  /// Gets visible fields for a form based on permissions
  static List<String> getVisibleFieldsForForm(
    PermissionsManager manager,
    List<String> allFields,
  ) {
    return allFields.where((field) => manager.canReadField(field)).toList();
  }

  /// Gets editable fields for a form based on permissions
  static List<String> getEditableFieldsForForm(
    PermissionsManager manager,
    List<String> allFields,
  ) {
    return allFields.where((field) => manager.canEditField(field)).toList();
  }

  /// Filters data for create operations based on permissions
  static Map<String, dynamic> filterForCreate(
    PermissionsManager manager,
    Map<String, dynamic> data,
  ) {
    if (!manager.hasPermissions) return data;
    
    // If no specific create restrictions, allow all editable fields
    final filtered = <String, dynamic>{};
    for (final entry in data.entries) {
      if (manager.canEditField(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered.isEmpty ? data : filtered;
  }

  /// Filters data for update operations based on permissions
  static Map<String, dynamic> filterForUpdate(
    PermissionsManager manager,
    Map<String, dynamic> data,
  ) {
    if (!manager.hasPermissions) return {};
    
    final filtered = <String, dynamic>{};
    for (final entry in data.entries) {
      if (manager.canEditField(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  /// Gets a list of all available permissions for debugging
  static Map<String, bool> getAllPermissions(PermissionsManager manager) {
    return {
      'create': manager.canCreate,
      'read': manager.canRead,
      'edit': manager.canEdit,
      'delete': manager.canDelete,
      'restore': manager.canRestore,
      'view_deleted': manager.canViewDeleted,
      'permanent_delete': manager.canPermanentDelete,
    };
  }

  /// Logs current permission status for debugging
  static void logPermissionStatus(PermissionsManager manager) {
    final permissions = getAllPermissions(manager);
    developer.log('📋 Current permissions:', name: 'PermissionsHelper');
    permissions.forEach((key, value) {
      developer.log('  $key: $value', name: 'PermissionsHelper');
    });
    
    if (manager.hasPermissions) {
      developer.log('📋 Field permissions:', name: 'PermissionsHelper');
      developer.log('  Visible fields: ${manager.visibleFields.length}', name: 'PermissionsHelper');
      developer.log('  Editable fields: ${manager.editableFields.length}', name: 'PermissionsHelper');
      developer.log('  Read-only fields: ${manager.readOnlyFields.length}', name: 'PermissionsHelper');
      developer.log('  Hidden fields: ${manager.hiddenFields.length}', name: 'PermissionsHelper');
    }
  }

  /// Validates if a user can perform a specific action on an autopsy
  static bool canPerformActionOnAutopsy(
    PermissionsManager manager,
    String action, {
    String? autopsyId,
    Map<String, dynamic>? autopsyData,
  }) {
    // Basic permission check
    if (!manager.canPerformAction(action)) {
      return false;
    }

    // TODO: Add item-specific permission checks here if needed
    // For example, check if user owns the autopsy, or if autopsy is in editable state
    
    return true;
  }

  /// Helper to check if all required fields are visible for a form
  static bool areRequiredFieldsVisible(
    PermissionsManager manager,
    List<String> requiredFields,
  ) {
    for (final field in requiredFields) {
      if (!manager.canReadField(field)) {
        developer.log('⚠️ Required field "$field" is not visible to user', name: 'PermissionsHelper');
        return false;
      }
    }
    return true;
  }

  /// Helper to check if all required fields are editable for a form
  static bool areRequiredFieldsEditable(
    PermissionsManager manager,
    List<String> requiredFields,
  ) {
    for (final field in requiredFields) {
      if (!manager.canEditField(field)) {
        developer.log('⚠️ Required field "$field" is not editable by user', name: 'PermissionsHelper');
        return false;
      }
    }
    return true;
  }

  /// Get missing permissions for debugging
  static Map<String, dynamic> getMissingPermissions(
    PermissionsManager manager,
    List<String> requiredActions,
    List<String> requiredFields,
  ) {
    final missingActions = <String>[];
    final missingFields = <String>[];

    for (final action in requiredActions) {
      if (!manager.canPerformAction(action)) {
        missingActions.add(action);
      }
    }

    for (final field in requiredFields) {
      if (!manager.canReadField(field)) {
        missingFields.add(field);
      }
    }

    return {
      'missingActions': missingActions,
      'missingFields': missingFields,
      'hasMissingPermissions': missingActions.isNotEmpty || missingFields.isNotEmpty,
    };
  }
}