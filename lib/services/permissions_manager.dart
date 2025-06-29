// lib/services/permissions_manager.dart
import 'package:flutter/foundation.dart';
import '../models/autopsy_models.dart';

class PermissionsManager extends ChangeNotifier {
  AutopsyPermissions? _permissions;
  bool _isLoading = false;
  String? _error;
  final Map<String, dynamic> _cache = {};

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

  Future<void> loadPermissions() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Simulate API call - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      _permissions = AutopsyPermissions(
        canRead: true,
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canRestore: true,
        canPermanentDelete: false,
        canViewDeleted: true,
        visibleFields: ['name', 'description', 'autopsystatus', 'autopsycomments'],
        editableFields: ['name', 'autopsystatus', 'autopsycomments'],
        creatableFields: ['name', 'description', 'autopsystatus', 'autopsycomments'],
      );

    } catch (error) {
      _error = error.toString();
      _permissions = AutopsyPermissions.defaultPermissions;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPermissions() {
    _permissions = null;
    _error = null;
    notifyListeners();
  }

  // Clear cache method (required by SettingsScreen)
  void clearCache() {
    _cache.clear();
    _permissions = null;
    _error = null;
    notifyListeners();
  }

  // Get debug summary (required by SettingsScreen)
  Map<String, dynamic> getDebugSummary() {
    return {
      'Has Permissions': hasPermissions,
      'Is Loading': isLoading,
      'Error': error ?? 'None',
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

  // Check if a specific field can be edited (required by AutopsyEditBottomSheet)
  bool canEditField(String fieldName) {
    if (_permissions == null) return false;
    return _permissions!.editableFields.contains(fieldName);
  }

  // Check if a specific field is visible
  bool canViewField(String fieldName) {
    if (_permissions == null) return false;
    return _permissions!.visibleFields.contains(fieldName);
  }

  // Check if a specific field can be created
  bool canCreateField(String fieldName) {
    if (_permissions == null) return false;
    return _permissions!.creatableFields.contains(fieldName);
  }

  // Get all visible fields
  List<String> getVisibleFields() {
    return _permissions?.visibleFields ?? [];
  }

  // Get all editable fields
  List<String> getEditableFields() {
    return _permissions?.editableFields ?? [];
  }

  // Get all creatable fields
  List<String> getCreatableFields() {
    return _permissions?.creatableFields ?? [];
  }

  // Check if user can perform specific action
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

  // Force refresh permissions from server
  Future<void> refreshPermissions() async {
    _permissions = null;
    _cache.clear();
    await loadPermissions();
  }

  // Add cache management
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