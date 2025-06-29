// lib/utils/permissions_helper.dart
import '../services/permissions_manager.dart';

class PermissionsHelper {
  static Future<void> ensurePermissionsLoaded(PermissionsManager manager) async {
    if (!manager.hasPermissions) {
      await manager.loadPermissions();
    }
  }
}