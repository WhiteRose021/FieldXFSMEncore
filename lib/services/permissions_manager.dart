// lib/services/permissions_manager.dart
import 'package:flutter/foundation.dart';
import '../models/autopsy_models.dart';

class PermissionsManager extends ChangeNotifier {
  AutopsyPermissions? _permissions;
  bool _isLoading = false;
  String? _error;

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
        visibleFields: [],
        editableFields: [],
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
}