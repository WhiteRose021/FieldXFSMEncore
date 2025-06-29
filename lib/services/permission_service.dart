// lib/services/permission_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Permission levels matching the backend RBAC system
enum PermissionLevel {
  no,
  yes, 
  team,
  own,
  all
}

/// Field permission levels
enum FieldPermissionLevel {
  no,
  yes
}

/// Entity permissions for CRUD operations
class EntityPermissions {
  final PermissionLevel create;
  final PermissionLevel read;
  final PermissionLevel edit;
  final PermissionLevel delete;
  final PermissionLevel stream;

  const EntityPermissions({
    required this.create,
    required this.read,
    required this.edit,
    required this.delete,
    required this.stream,
  });

  factory EntityPermissions.fromJson(Map<String, dynamic> json) {
    return EntityPermissions(
      create: _parsePermissionLevel(json['create']),
      read: _parsePermissionLevel(json['read']),
      edit: _parsePermissionLevel(json['edit']),
      delete: _parsePermissionLevel(json['delete']),
      stream: _parsePermissionLevel(json['stream']),
    );
  }

  static PermissionLevel _parsePermissionLevel(dynamic value) {
    if (value == null) return PermissionLevel.no;
    
    switch (value.toString().toLowerCase()) {
      case 'yes':
      case 'true':
        return PermissionLevel.yes;
      case 'team':
        return PermissionLevel.team;
      case 'own':
        return PermissionLevel.own;
      case 'all':
        return PermissionLevel.all;
      default:
        return PermissionLevel.no;
    }
  }

  bool get canCreate => [PermissionLevel.yes, PermissionLevel.team, PermissionLevel.own, PermissionLevel.all].contains(create);
  bool get canReadAny => [PermissionLevel.yes, PermissionLevel.team, PermissionLevel.own, PermissionLevel.all].contains(read);
  bool get canEditAny => [PermissionLevel.yes, PermissionLevel.team, PermissionLevel.own, PermissionLevel.all].contains(edit);
  bool get canDeleteAny => [PermissionLevel.yes, PermissionLevel.team, PermissionLevel.own, PermissionLevel.all].contains(delete);
}

/// Field permissions
class FieldPermissions {
  final FieldPermissionLevel read;
  final FieldPermissionLevel edit;

  const FieldPermissions({
    required this.read,
    required this.edit,
  });

  factory FieldPermissions.fromJson(Map<String, dynamic> json) {
    return FieldPermissions(
      read: _parseFieldPermissionLevel(json['read']),
      edit: _parseFieldPermissionLevel(json['edit']),
    );
  }

  static FieldPermissionLevel _parseFieldPermissionLevel(dynamic value) {
    if (value == null) return FieldPermissionLevel.no;
    return value.toString().toLowerCase() == 'yes' || value == true 
        ? FieldPermissionLevel.yes 
        : FieldPermissionLevel.no;
  }

  bool get canRead => read == FieldPermissionLevel.yes;
  bool get canEdit => edit == FieldPermissionLevel.yes;
}

/// Computed permissions for a user
class ComputedPermissions {
  final bool isAdmin;
  final bool isSuperAdmin;
  final Map<String, EntityPermissions> entityPermissions;
  final Map<String, Map<String, FieldPermissions>> fieldPermissions;
  final List<String> teamIds;
  final List<String> roleIds;
  final DateTime computedAt;

  const ComputedPermissions({
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.entityPermissions,
    required this.fieldPermissions,
    required this.teamIds,
    required this.roleIds,
    required this.computedAt,
  });

  factory ComputedPermissions.fromJson(Map<String, dynamic> json) {
    final entityPerms = <String, EntityPermissions>{};
    final fieldPerms = <String, Map<String, FieldPermissions>>{};

    // Parse entity permissions
    if (json['entities'] != null) {
      (json['entities'] as Map<String, dynamic>).forEach((key, value) {
        entityPerms[key] = EntityPermissions.fromJson(value);
      });
    }

    // Parse field permissions
    if (json['fields'] != null) {
      (json['fields'] as Map<String, dynamic>).forEach((entityType, fields) {
        fieldPerms[entityType] = <String, FieldPermissions>{};
        if (fields is Map<String, dynamic>) {
          fields.forEach((fieldName, fieldPerm) {
            fieldPerms[entityType]![fieldName] = FieldPermissions.fromJson(fieldPerm);
          });
        }
      });
    }

    return ComputedPermissions(
      isAdmin: json['system']?['isAdmin'] ?? false,
      isSuperAdmin: json['system']?['isSuperAdmin'] ?? false,
      entityPermissions: entityPerms,
      fieldPermissions: fieldPerms,
      teamIds: List<String>.from(json['teams']?['memberOf'] ?? []),
      roleIds: List<String>.from(json['roleIds'] ?? []),
      computedAt: DateTime.now(),
    );
  }
}

/// Enhanced Permission Service that mirrors the backend permission system
class PermissionService {
  static const String _apiKey = '5af9459182c0ae4e1606e5d65864df25';
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();

  PermissionService._();

  ComputedPermissions? _cachedPermissions;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTimeout = Duration(minutes: 30);

  Future<String?> _getCRMBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('crmDomain');
  }

  Future<String?> _getBasicAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    
    if (username == null || password == null) return null;
    
    return base64Encode(utf8.encode('$username:$password'));
  }

  /// Get computed permissions for the current user
  Future<ComputedPermissions?> getComputedPermissions() async {
    try {
      // Check cache first
      if (_cachedPermissions != null && 
          _cacheTimestamp != null && 
          DateTime.now().difference(_cacheTimestamp!) < _cacheTimeout) {
        return _cachedPermissions;
      }

      final crmBaseUrl = await _getCRMBaseUrl();
      final basicAuth = await _getBasicAuth();
      
      if (crmBaseUrl == null || basicAuth == null) {
        developer.log('❌ Missing CRM URL or authentication');
        return null;
      }

      // First get user details to get user ID
      final userRes = await http.get(
        Uri.parse('$crmBaseUrl/api/v1/App/user'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'X-Api-Key': _apiKey,
        },
      );

      if (userRes.statusCode != 200) {
        developer.log('❌ Failed to get user details: ${userRes.statusCode}');
        return null;
      }

      final userData = json.decode(userRes.body);
      final userId = userData['user']?['id'];
      
      if (userId == null) {
        developer.log('❌ User ID not found in response');
        return null;
      }

      // Get user's roles and teams
      final rolesTeamsRes = await http.get(
        Uri.parse('$crmBaseUrl/api/v1/User/$userId'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'X-Api-Key': _apiKey,
        },
      );

      if (rolesTeamsRes.statusCode != 200) {
        developer.log('❌ Failed to get user roles and teams: ${rolesTeamsRes.statusCode}');
        return null;
      }

      final userDetails = json.decode(rolesTeamsRes.body);
      
      // Extract role and team information
      final roleIds = _extractIds(userDetails['rolesIds']);
      final teamIds = _extractIds(userDetails['teamsIds']);
      final isAdmin = userDetails['type'] == 'admin';
      final isSuperAdmin = userDetails['type'] == 'superadmin' || userDetails['isAdmin'] == true;

      // Fetch detailed role permissions
      final entityPermissions = <String, EntityPermissions>{};
      final fieldPermissions = <String, Map<String, FieldPermissions>>{};

      for (final roleId in roleIds) {
        final rolePermissions = await _fetchRolePermissions(roleId, basicAuth, crmBaseUrl);
        _mergePermissions(entityPermissions, fieldPermissions, rolePermissions);
      }

      final permissions = ComputedPermissions(
        isAdmin: isAdmin,
        isSuperAdmin: isSuperAdmin,
        entityPermissions: entityPermissions,
        fieldPermissions: fieldPermissions,
        teamIds: teamIds,
        roleIds: roleIds,
        computedAt: DateTime.now(),
      );

      // Cache the permissions
      _cachedPermissions = permissions;
      _cacheTimestamp = DateTime.now();

      developer.log('✅ Successfully computed permissions for user $userId');
      _logPermissionsSummary(permissions);

      return permissions;

    } catch (e) {
      developer.log('❌ Error computing permissions: $e');
      return null;
    }
  }

  /// Check if user can perform action on specific entity type
  Future<bool> canPerformAction(String entityType, String action, {
    String? entityId,
    Map<String, dynamic>? entityData
  }) async {
    final permissions = await getComputedPermissions();
    
    if (permissions == null) {
      developer.log('❌ No permissions found for action check');
      return false;
    }

    // Super admin and admin bypass
    if (permissions.isSuperAdmin || permissions.isAdmin) {
      return true;
    }

    final entityPerms = permissions.entityPermissions[entityType];
    if (entityPerms == null) {
      developer.log('❌ No entity permissions found for $entityType');
      return false;
    }

    PermissionLevel permissionLevel;
    switch (action.toLowerCase()) {
      case 'create':
        permissionLevel = entityPerms.create;
        break;
      case 'read':
        permissionLevel = entityPerms.read;
        break;
      case 'edit':
      case 'update':
        permissionLevel = entityPerms.edit;
        break;
      case 'delete':
        permissionLevel = entityPerms.delete;
        break;
      default:
        developer.log('❌ Unknown action: $action');
        return false;
    }

    return await _evaluatePermissionLevel(
      permissionLevel, 
      permissions.teamIds, 
      entityData
    );
  }

  /// Check if user can read/edit specific field
  Future<bool> canAccessField(String entityType, String fieldName, String action) async {
    final permissions = await getComputedPermissions();
    
    if (permissions == null) return false;

    // Super admin and admin bypass
    if (permissions.isSuperAdmin || permissions.isAdmin) {
      return true;
    }

    final entityFieldPerms = permissions.fieldPermissions[entityType];
    if (entityFieldPerms == null) return true; // Default to allow if no field permissions

    final fieldPerm = entityFieldPerms[fieldName];
    if (fieldPerm == null) return true; // Default to allow if field not specified

    switch (action.toLowerCase()) {
      case 'read':
        return fieldPerm.canRead;
      case 'edit':
      case 'update':
        return fieldPerm.canEdit;
      default:
        return false;
    }
  }

  /// Get visible fields for an entity type
  Future<List<String>> getVisibleFields(String entityType, List<String> allFields) async {
    final permissions = await getComputedPermissions();
    
    if (permissions == null) return allFields;

    // Super admin and admin see all fields
    if (permissions.isSuperAdmin || permissions.isAdmin) {
      return allFields;
    }

    final visibleFields = <String>[];
    
    for (final field in allFields) {
      if (await canAccessField(entityType, field, 'read')) {
        visibleFields.add(field);
      }
    }

    return visibleFields;
  }

  /// Get editable fields for an entity type
  Future<List<String>> getEditableFields(String entityType, List<String> allFields) async {
    final permissions = await getComputedPermissions();
    
    if (permissions == null) return [];

    // Super admin and admin can edit all fields
    if (permissions.isSuperAdmin || permissions.isAdmin) {
      return allFields;
    }

    final editableFields = <String>[];
    
    for (final field in allFields) {
      if (await canAccessField(entityType, field, 'edit')) {
        editableFields.add(field);
      }
    }

    return editableFields;
  }

  /// Clear cached permissions (call after login/logout)
  void clearPermissionCache() {
    _cachedPermissions = null;
    _cacheTimestamp = null;
    developer.log('🧽 Cleared permission cache');
  }

  // ============= PRIVATE HELPER METHODS =============

  List<String> _extractIds(dynamic value) {
    if (value == null) return [];
    
    if (value is Map<String, dynamic>) {
      return value.keys.toList();
    } else if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    
    return [];
  }

  Future<Map<String, dynamic>> _fetchRolePermissions(String roleId, String basicAuth, String crmBaseUrl) async {
    try {
      final roleRes = await http.get(
        Uri.parse('$crmBaseUrl/api/v1/Role/$roleId'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'X-Api-Key': _apiKey,
        },
      );

      if (roleRes.statusCode == 200) {
        return json.decode(roleRes.body);
      }
    } catch (e) {
      developer.log('❌ Failed to fetch role permissions for $roleId: $e');
    }

    return {};
  }

  void _mergePermissions(
    Map<String, EntityPermissions> entityPermissions,
    Map<String, Map<String, FieldPermissions>> fieldPermissions,
    Map<String, dynamic> roleData
  ) {
    // Merge entity permissions from role data
    if (roleData['data'] != null) {
      final entityData = roleData['data'] as Map<String, dynamic>;
      entityData.forEach((entityType, perms) {
        if (perms is Map<String, dynamic>) {
          final newPerms = EntityPermissions.fromJson(perms);
          
          if (entityPermissions.containsKey(entityType)) {
            // Merge with existing permissions (take maximum)
            final existing = entityPermissions[entityType]!;
            entityPermissions[entityType] = EntityPermissions(
              create: _maxPermissionLevel(existing.create, newPerms.create),
              read: _maxPermissionLevel(existing.read, newPerms.read),
              edit: _maxPermissionLevel(existing.edit, newPerms.edit),
              delete: _maxPermissionLevel(existing.delete, newPerms.delete),
              stream: _maxPermissionLevel(existing.stream, newPerms.stream),
            );
          } else {
            entityPermissions[entityType] = newPerms;
          }
        }
      });
    }

    // Merge field permissions from role field_data
    if (roleData['field_data'] != null) {
      final fieldData = roleData['field_data'] as Map<String, dynamic>;
      fieldData.forEach((entityType, entityFields) {
        if (entityFields is Map<String, dynamic>) {
          fieldPermissions[entityType] ??= <String, FieldPermissions>{};
          
          entityFields.forEach((fieldName, fieldPerms) {
            if (fieldPerms is Map<String, dynamic>) {
              final newFieldPerms = FieldPermissions.fromJson(fieldPerms);
              
              if (fieldPermissions[entityType]!.containsKey(fieldName)) {
                // Merge with existing (take maximum)
                final existing = fieldPermissions[entityType]![fieldName]!;
                fieldPermissions[entityType]![fieldName] = FieldPermissions(
                  read: existing.read == FieldPermissionLevel.yes || newFieldPerms.read == FieldPermissionLevel.yes
                      ? FieldPermissionLevel.yes 
                      : FieldPermissionLevel.no,
                  edit: existing.edit == FieldPermissionLevel.yes || newFieldPerms.edit == FieldPermissionLevel.yes
                      ? FieldPermissionLevel.yes 
                      : FieldPermissionLevel.no,
                );
              } else {
                fieldPermissions[entityType]![fieldName] = newFieldPerms;
              }
            }
          });
        }
      });
    }
  }

  PermissionLevel _maxPermissionLevel(PermissionLevel a, PermissionLevel b) {
    const levels = [
      PermissionLevel.no,
      PermissionLevel.own,
      PermissionLevel.team,
      PermissionLevel.yes,
      PermissionLevel.all,
    ];
    
    final aIndex = levels.indexOf(a);
    final bIndex = levels.indexOf(b);
    
    return levels[aIndex > bIndex ? aIndex : bIndex];
  }

  Future<bool> _evaluatePermissionLevel(
    PermissionLevel level, 
    List<String> userTeamIds, 
    Map<String, dynamic>? entityData
  ) async {
    switch (level) {
      case PermissionLevel.no:
        return false;
        
      case PermissionLevel.yes:
      case PermissionLevel.all:
        return true;
        
      case PermissionLevel.own:
        if (entityData == null) return true; // For create operations
        
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('userId');
        
        // Check various ownership fields
        final ownerId = entityData['assigned_user_id'] ?? 
                       entityData['created_by'] ?? 
                       entityData['owner_user_id'];
        
        return ownerId == currentUserId;
        
      case PermissionLevel.team:
        if (entityData == null) return true; // For create operations
        
        // Check if entity is assigned to any of user's teams
        final entityTeamIds = _extractTeamIds(entityData);
        return entityTeamIds.any((teamId) => userTeamIds.contains(teamId));
    }
  }

  List<String> _extractTeamIds(Map<String, dynamic> entityData) {
    final teamIds = <String>[];
    
    // Check various team fields
    final assignedTeamId = entityData['assigned_team_id'];
    if (assignedTeamId != null) teamIds.add(assignedTeamId.toString());
    
    final teamId = entityData['team_id'];
    if (teamId != null) teamIds.add(teamId.toString());
    
    final teamsIds = entityData['teams_ids'];
    if (teamsIds != null) {
      teamIds.addAll(_extractIds(teamsIds));
    }
    
    return teamIds;
  }

  void _logPermissionsSummary(ComputedPermissions permissions) {
    developer.log('🔒 === PERMISSION SUMMARY ===');
    developer.log('👑 Admin: ${permissions.isAdmin}');
    developer.log('⭐ Super Admin: ${permissions.isSuperAdmin}');
    developer.log('👥 Teams: ${permissions.teamIds}');
    developer.log('🎭 Roles: ${permissions.roleIds}');
    
    permissions.entityPermissions.forEach((entity, perms) {
      developer.log('📋 $entity: C:${perms.create.name} R:${perms.read.name} U:${perms.edit.name} D:${perms.delete.name}');
    });
  }
}