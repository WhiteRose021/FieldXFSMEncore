// lib/widgets/permission_guard.dart
import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Widget that conditionally shows/hides content based on permissions
class PermissionGuard extends StatefulWidget {
  final String entityType;
  final String action;
  final Widget child;
  final Widget? fallback;
  final String? entityId;
  final Map<String, dynamic>? entityData;
  final String? fieldName;

  const PermissionGuard({
    super.key,
    required this.entityType,
    required this.action,
    required this.child,
    this.fallback,
    this.entityId,
    this.entityData,
    this.fieldName,
  });

  /// Factory for field-level permissions
  factory PermissionGuard.field({
    Key? key,
    required String entityType,
    required String fieldName,
    required String action,
    required Widget child,
    Widget? fallback,
  }) {
    return PermissionGuard(
      key: key,
      entityType: entityType,
      action: action,
      child: child,
      fallback: fallback,
      fieldName: fieldName,
    );
  }

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard> {
  bool? _hasPermission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void didUpdateWidget(PermissionGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Re-check permission if relevant parameters changed
    if (oldWidget.entityType != widget.entityType ||
        oldWidget.action != widget.action ||
        oldWidget.entityId != widget.entityId ||
        oldWidget.fieldName != widget.fieldName) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    setState(() => _isLoading = true);
    
    try {
      bool hasPermission;
      
      if (widget.fieldName != null) {
        // Field-level permission check
        hasPermission = await PermissionService.instance.canAccessField(
          widget.entityType,
          widget.fieldName!,
          widget.action,
        );
      } else {
        // Entity-level permission check
        hasPermission = await PermissionService.instance.canPerformAction(
          widget.entityType,
          widget.action,
          entityId: widget.entityId,
          entityData: widget.entityData,
        );
      }
      
      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    } catch (e) {
      // On error, default to no permission
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Don't show loading, just hide
    }

    if (_hasPermission == true) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Mixin for pages that need permission checking
mixin PermissionMixin<T extends StatefulWidget> on State<T> {
  bool _permissionsLoaded = false;
  ComputedPermissions? _userPermissions;

  Future<void> initializePermissions() async {
    _userPermissions = await PermissionService.instance.getComputedPermissions();
    setState(() => _permissionsLoaded = true);
  }

  bool get permissionsLoaded => _permissionsLoaded;
  ComputedPermissions? get userPermissions => _userPermissions;

  Future<bool> checkEntityPermission(String entityType, String action, {
    String? entityId,
    Map<String, dynamic>? entityData,
  }) async {
    return await PermissionService.instance.canPerformAction(
      entityType,
      action,
      entityId: entityId,
      entityData: entityData,
    );
  }

  Future<bool> checkFieldPermission(String entityType, String fieldName, String action) async {
    return await PermissionService.instance.canAccessField(entityType, fieldName, action);
  }
}