// lib/widgets/permission_guard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/permissions_manager.dart';

/// Widget that conditionally shows/hides content based on permissions
class PermissionGuard extends StatelessWidget {
  final String action;
  final Widget child;
  final Widget? fallback;
  final String? fieldName;

  const PermissionGuard({
    super.key,
    required this.action,
    required this.child,
    this.fallback,
    this.fieldName,
  });

  /// Factory for field-level permissions
  factory PermissionGuard.field({
    Key? key,
    required String fieldName,
    required String action, // 'read' or 'edit'
    required Widget child,
    Widget? fallback,
  }) {
    return PermissionGuard(
      key: key,
      action: action,
      child: child,
      fallback: fallback,
      fieldName: fieldName,
    );
  }

  /// Factory for create permission
  factory PermissionGuard.create({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) {
    return PermissionGuard(
      key: key,
      action: 'create',
      child: child,
      fallback: fallback,
    );
  }

  /// Factory for edit permission
  factory PermissionGuard.edit({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) {
    return PermissionGuard(
      key: key,
      action: 'edit',
      child: child,
      fallback: fallback,
    );
  }

  /// Factory for delete permission
  factory PermissionGuard.delete({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) {
    return PermissionGuard(
      key: key,
      action: 'delete',
      child: child,
      fallback: fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionsManager>(
      builder: (context, permissionsManager, _) {
        // If permissions aren't loaded yet, don't show anything
        if (!permissionsManager.hasPermissions) {
          return const SizedBox.shrink();
        }

        bool hasPermission = false;

        if (fieldName != null) {
          // Field-level permission check
          switch (action) {
            case 'read':
            case 'view':
              hasPermission = permissionsManager.permissions!.visibleFields.isEmpty ||
                  permissionsManager.permissions!.visibleFields.contains(fieldName);
              break;
            case 'edit':
            case 'write':
              hasPermission = permissionsManager.permissions!.editableFields.contains(fieldName);
              break;
            case 'create':
              hasPermission = permissionsManager.permissions!.creatableFields.contains(fieldName);
              break;
            default:
              hasPermission = false;
          }
        } else {
          // Entity-level permission check
          switch (action) {
            case 'create':
              hasPermission = permissionsManager.canCreate;
              break;
            case 'read':
            case 'view':
              hasPermission = true; // Reading is generally allowed if user has access
              break;
            case 'edit':
            case 'update':
              hasPermission = permissionsManager.canEdit;
              break;
            case 'delete':
              hasPermission = permissionsManager.canDelete;
              break;
            case 'restore':
              hasPermission = permissionsManager.canRestore;
              break;
            case 'view_deleted':
              hasPermission = permissionsManager.canViewDeleted;
              break;
            default:
              hasPermission = false;
          }
        }

        if (hasPermission) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Simple permission checking utilities
class PermissionUtils {
  /// Check if user can perform an action
  static bool canPerformAction(PermissionsManager manager, String action) {
    if (!manager.hasPermissions) return false;

    switch (action) {
      case 'create':
        return manager.canCreate;
      case 'read':
      case 'view':
        return true; // Reading is generally allowed
      case 'edit':
      case 'update':
        return manager.canEdit;
      case 'delete':
        return manager.canDelete;
      case 'restore':
        return manager.canRestore;
      case 'view_deleted':
        return manager.canViewDeleted;
      default:
        return false;
    }
  }

  /// Check if user can access a field
  static bool canAccessField(PermissionsManager manager, String fieldName, String action) {
    if (!manager.hasPermissions) return false;

    switch (action) {
      case 'read':
      case 'view':
        return manager.permissions!.visibleFields.isEmpty ||
            manager.permissions!.visibleFields.contains(fieldName);
      case 'edit':
      case 'write':
        return manager.permissions!.editableFields.contains(fieldName);
      case 'create':
        return manager.permissions!.creatableFields.contains(fieldName);
      default:
        return false;
    }
  }

  /// Get all actions a user can perform
  static List<String> getAllowedActions(PermissionsManager manager) {
    if (!manager.hasPermissions) return [];

    final actions = <String>[];
    
    if (manager.canCreate) actions.add('create');
    if (manager.canEdit) actions.add('edit');
    if (manager.canDelete) actions.add('delete');
    if (manager.canRestore) actions.add('restore');
    if (manager.canViewDeleted) actions.add('view_deleted');

    return actions;
  }
}

/// Mixin for pages that need permission checking
mixin PermissionMixin<T extends StatefulWidget> on State<T> {
  PermissionsManager? _permissionsManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _permissionsManager = Provider.of<PermissionsManager>(context, listen: false);
  }

  /// Check if user can perform an action
  bool canPerformAction(String action) {
    if (_permissionsManager == null) return false;
    return PermissionUtils.canPerformAction(_permissionsManager!, action);
  }

  /// Check if user can access a field
  bool canAccessField(String fieldName, String action) {
    if (_permissionsManager == null) return false;
    return PermissionUtils.canAccessField(_permissionsManager!, fieldName, action);
  }

  /// Check if user has any permissions loaded
  bool get hasPermissions => _permissionsManager?.hasPermissions ?? false;

  /// Get all actions user can perform
  List<String> get allowedActions {
    if (_permissionsManager == null) return [];
    return PermissionUtils.getAllowedActions(_permissionsManager!);
  }

  /// Show permission denied message
  void showPermissionDenied([String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Permission denied'),
        backgroundColor: Colors.red,
      ),
    );
  }
}