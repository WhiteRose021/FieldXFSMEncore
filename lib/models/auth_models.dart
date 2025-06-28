// lib/models/auth_models.dart

/// Login response from Encore backend
class LoginResponse {
  final String token;
  final String sessionId;
  final User user;
  final int expiresIn;

  LoginResponse({
    required this.token,
    required this.sessionId,
    required this.user,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      sessionId: json['sessionId'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      expiresIn: json['expiresIn'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'sessionId': sessionId,
      'user': user.toJson(),
      'expiresIn': expiresIn,
    };
  }
}

/// User model matching Encore backend structure
class User {
  final String id;
  final String username;
  final String type;
  final String? firstName;
  final String? lastName;
  final String tenantId;
  final String tenantName;
  final UserPermissions permissions;
  final Tenant? tenant;

  User({
    required this.id,
    required this.username,
    required this.type,
    this.firstName,
    this.lastName,
    required this.tenantId,
    required this.tenantName,
    required this.permissions,
    this.tenant,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      type: json['type'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String,
      permissions: UserPermissions.fromJson(json['permissions'] as Map<String, dynamic>),
      tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'type': type,
      'firstName': firstName,
      'lastName': lastName,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'permissions': permissions.toJson(),
      'tenant': tenant?.toJson(),
    };
  }

  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return username;
  }

  bool get isAdmin => type == 'admin' || permissions.isAdmin;
  bool get isSuperAdmin => permissions.isSuperAdmin;
}

/// User permissions matching Encore backend structure
class UserPermissions {
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool canExport;
  final bool canMassUpdate;
  final bool canAudit;
  final bool canManageUsers;

  UserPermissions({
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.canExport,
    required this.canMassUpdate,
    required this.canAudit,
    required this.canManageUsers,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      isAdmin: json['isAdmin'] as bool? ?? false,
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
      canExport: json['canExport'] as bool? ?? false,
      canMassUpdate: json['canMassUpdate'] as bool? ?? false,
      canAudit: json['canAudit'] as bool? ?? false,
      canManageUsers: json['canManageUsers'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'canExport': canExport,
      'canMassUpdate': canMassUpdate,
      'canAudit': canAudit,
      'canManageUsers': canManageUsers,
    };
  }
}

/// Tenant information
class Tenant {
  final String id;
  final String name;
  final String tenantCode;
  final String displayName;
  final String status;

  Tenant({
    required this.id,
    required this.name,
    required this.tenantCode,
    required this.displayName,
    required this.status,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      tenantCode: json['tenantCode'] as String,
      displayName: json['displayName'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tenantCode': tenantCode,
      'displayName': displayName,
      'status': status,
    };
  }
}

/// User role information
class UserRole {
  final String id;
  final String name;
  final RolePermissions permissions;

  UserRole({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as String,
      name: json['name'] as String,
      permissions: RolePermissions.fromJson(json['permissions'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions.toJson(),
    };
  }
}

/// Role permissions structure
class RolePermissions {
  final String assignmentPermission;
  final String userPermission;
  final String exportPermission;
  final String massUpdatePermission;
  final String dataPrivacyPermission;
  final String auditPermission;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? fieldData;

  RolePermissions({
    required this.assignmentPermission,
    required this.userPermission,
    required this.exportPermission,
    required this.massUpdatePermission,
    required this.dataPrivacyPermission,
    required this.auditPermission,
    this.data,
    this.fieldData,
  });

  factory RolePermissions.fromJson(Map<String, dynamic> json) {
    return RolePermissions(
      assignmentPermission: json['assignment_permission'] as String,
      userPermission: json['user_permission'] as String,
      exportPermission: json['export_permission'] as String,
      massUpdatePermission: json['mass_update_permission'] as String,
      dataPrivacyPermission: json['data_privacy_permission'] as String,
      auditPermission: json['audit_permission'] as String,
      data: json['data'] as Map<String, dynamic>?,
      fieldData: json['field_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_permission': assignmentPermission,
      'user_permission': userPermission,
      'export_permission': exportPermission,
      'mass_update_permission': massUpdatePermission,
      'data_privacy_permission': dataPrivacyPermission,
      'audit_permission': auditPermission,
      'data': data,
      'field_data': fieldData,
    };
  }
}

/// User team information
class UserTeam {
  final String id;
  final String name;
  final String role; // member, leader, manager

  UserTeam({
    required this.id,
    required this.name,
    required this.role,
  });

  factory UserTeam.fromJson(Map<String, dynamic> json) {
    return UserTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }
}

/// Combined user roles and teams response
class UserRolesAndTeams {
  final List<UserRole> roles;
  final List<UserTeam> teams;

  UserRolesAndTeams({
    required this.roles,
    required this.teams,
  });

  factory UserRolesAndTeams.fromJson(Map<String, dynamic> json) {
    return UserRolesAndTeams(
      roles: (json['roles'] as List<dynamic>?)
          ?.map((role) => UserRole.fromJson(role as Map<String, dynamic>))
          .toList() ?? [],
      teams: (json['teams'] as List<dynamic>?)
          ?.map((team) => UserTeam.fromJson(team as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roles': roles.map((role) => role.toJson()).toList(),
      'teams': teams.map((team) => team.toJson()).toList(),
    };
  }
}

/// Session check response
class SessionCheckResponse {
  final bool valid;
  final int? timeLeft;

  SessionCheckResponse({
    required this.valid,
    this.timeLeft,
  });

  factory SessionCheckResponse.fromJson(Map<String, dynamic> json) {
    return SessionCheckResponse(
      valid: json['valid'] as bool,
      timeLeft: json['timeLeft'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      'timeLeft': timeLeft,
    };
  }
}