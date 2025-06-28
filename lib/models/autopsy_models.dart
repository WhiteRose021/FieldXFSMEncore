// lib/models/autopsy_models.dart - FIXED VERSION
import 'package:json_annotation/json_annotation.dart';

part 'autopsy_models.g.dart';

// Core Autopsy Model
@JsonSerializable()
// Replace your entire CAutopsy class in lib/models/autopsy_models.dart with this:

@JsonSerializable()
class CAutopsy {
  final String id;
  final String? name;
  final bool? deleted;
  final String? description;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'modified_at')
  final DateTime? modifiedAt;
  @JsonKey(name: 'created_by_id')
  final String? createdById;
  @JsonKey(name: 'modified_by_id')
  final String? modifiedById;
  @JsonKey(name: 'assigned_user_id')
  final String? assignedUserId;
  @JsonKey(name: 'tenant_id')
  final String? tenantId;
  @JsonKey(name: 'stream_updated_at')
  final DateTime? streamUpdatedAt;
  @JsonKey(name: 'version_number')
  final int? versionNumber;
  
  // Autopsy specific fields
  @JsonKey(name: 'autopsyfulladdress')
  final String? autopsyFullAddress;
  @JsonKey(name: 'autopsystreet')
  final String? autopsyStreet;
  @JsonKey(name: 'autopsypostalcode')
  final String? autopsyPostalCode;
  @JsonKey(name: 'autopsymunicipality')
  final String? autopsyMunicipality;
  @JsonKey(name: 'autopsystate')
  final String? autopsyState;
  @JsonKey(name: 'autopsycity')
  final String? autopsyCity;
  @JsonKey(name: 'autopsyage')
  final String? autopsyAge;
  @JsonKey(name: 'autopsyak')
  final String? autopsyAk;
  @JsonKey(name: 'autopsyadminemail')
  final String? autopsyAdminEmail;
  @JsonKey(name: 'autopsyadminmobile')
  final String? autopsyAdminMobile;
  @JsonKey(name: 'autopsylandlinephonenumber')
  final String? autopsyLandlinePhoneNumber;
  @JsonKey(name: 'autopsybid')
  final String? autopsyBid;
  @JsonKey(name: 'autopsycab')
  final String? autopsyCab;
  @JsonKey(name: 'autopsycategory')
  final String? autopsyCategory;
  @JsonKey(name: 'autopsycustomeremail')
  final String? autopsyCustomerEmail;
  @JsonKey(name: 'autopsycustomermobile')
  final String? autopsyCustomerMobile;
  @JsonKey(name: 'autopsyoutofsystem')
  final bool? autopsyOutOfSystem;
  @JsonKey(name: 'autopsycustomerfloor')
  final String? autopsyCustomerFloor;
  @JsonKey(name: 'autopsylatitude')
  final String? autopsyLatitude;
  @JsonKey(name: 'autopsylongtitude')
  final String? autopsyLongitude;
  @JsonKey(name: 'autopsyordernumber')
  final String? autopsyOrderNumber;
  @JsonKey(name: 'autopsypilot')
  final String? autopsyPilot;
  @JsonKey(name: 'autopsystatus')
  final String? autopsyStatus;
  @JsonKey(name: 'autopsycomments')
  final String? autopsyComments;
  @JsonKey(name: 'autopsyttlp')
  final String? autopsyTtlp;
  @JsonKey(name: 'autopsyttllppptest')
  final String? autopsyTtllpppTest;
  @JsonKey(name: 'building_id')
  final String? buildingId;
  @JsonKey(name: 'autopsycustomername')
  final String? autopsyCustomerName;
  final String? type;
  @JsonKey(name: 'adminautopsyname')
  final String? adminAutopsyName;
  @JsonKey(name: 'autopsyadminlandline')
  final String? autopsyAdminLandline;
  
  // Status fields
  @JsonKey(name: 'technicalcheckstatus')
  final String? technicalCheckStatus;
  @JsonKey(name: 'soilworkstatus')
  final String? soilWorkStatus;
  @JsonKey(name: 'constructionstatus')
  final String? constructionStatus;
  @JsonKey(name: 'splicingstatus')
  final String? splicingStatus;
  @JsonKey(name: 'billingstatus')
  final String? billingStatus;
  @JsonKey(name: 'malfunctionstatus')
  final String? malfunctionStatus;

  const CAutopsy({
    required this.id,
    this.name,
    this.deleted,
    this.description,
    this.createdAt,
    this.modifiedAt,
    this.createdById,
    this.modifiedById,
    this.assignedUserId,
    this.tenantId,
    this.streamUpdatedAt,
    this.versionNumber,
    this.autopsyFullAddress,
    this.autopsyStreet,
    this.autopsyPostalCode,
    this.autopsyMunicipality,
    this.autopsyState,
    this.autopsyCity,
    this.autopsyAge,
    this.autopsyAk,
    this.autopsyAdminEmail,
    this.autopsyAdminMobile,
    this.autopsyLandlinePhoneNumber,
    this.autopsyBid,
    this.autopsyCab,
    this.autopsyCategory,
    this.autopsyCustomerEmail,
    this.autopsyCustomerMobile,
    this.autopsyOutOfSystem,
    this.autopsyCustomerFloor,
    this.autopsyLatitude,
    this.autopsyLongitude,
    this.autopsyOrderNumber,
    this.autopsyPilot,
    this.autopsyStatus,
    this.autopsyComments,
    this.autopsyTtlp,
    this.autopsyTtllpppTest,
    this.buildingId,
    this.autopsyCustomerName,
    this.type,
    this.adminAutopsyName,
    this.autopsyAdminLandline,
    this.technicalCheckStatus,
    this.soilWorkStatus,
    this.constructionStatus,
    this.splicingStatus,
    this.billingStatus,
    this.malfunctionStatus,
  });

  // FIXED: Custom fromJson that handles ALL int-to-bool conversions safely
  factory CAutopsy.fromJson(Map<String, dynamic> json) {
    try {
      return CAutopsy(
        id: json['id']?.toString() ?? '',
        name: _safeString(json['name']),
        deleted: _safeBool(json['deleted']), // FIXED: Safe bool conversion
        description: _safeString(json['description']),
        createdAt: _safeDateTime(json['created_at']),
        modifiedAt: _safeDateTime(json['modified_at']),
        createdById: _safeString(json['created_by_id']),
        modifiedById: _safeString(json['modified_by_id']),
        assignedUserId: _safeString(json['assigned_user_id']),
        tenantId: _safeString(json['tenant_id']),
        streamUpdatedAt: _safeDateTime(json['stream_updated_at']),
        versionNumber: _safeInt(json['version_number']),
        autopsyFullAddress: _safeString(json['autopsyfulladdress']),
        autopsyStreet: _safeString(json['autopsystreet']),
        autopsyPostalCode: _safeString(json['autopsypostalcode']),
        autopsyMunicipality: _safeString(json['autopsymunicipality']),
        autopsyState: _safeString(json['autopsystate']),
        autopsyCity: _safeString(json['autopsycity']),
        autopsyAge: _safeString(json['autopsyage']),
        autopsyAk: _safeString(json['autopsyak']),
        autopsyAdminEmail: _safeString(json['autopsyadminemail']),
        autopsyAdminMobile: _safeString(json['autopsyadminmobile']),
        autopsyLandlinePhoneNumber: _safeString(json['autopsylandlinephonenumber']),
        autopsyBid: _safeString(json['autopsybid']),
        autopsyCab: _safeString(json['autopsycab']),
        autopsyCategory: _safeString(json['autopsycategory']),
        autopsyCustomerEmail: _safeString(json['autopsycustomeremail']),
        autopsyCustomerMobile: _safeString(json['autopsycustomermobile']),
        autopsyOutOfSystem: _safeBool(json['autopsyoutofsystem']), // FIXED: Safe bool conversion
        autopsyCustomerFloor: _safeString(json['autopsycustomerfloor']),
        autopsyLatitude: _safeString(json['autopsylatitude']),
        autopsyLongitude: _safeString(json['autopsylongtitude']),
        autopsyOrderNumber: _safeString(json['autopsyordernumber']),
        autopsyPilot: _safeString(json['autopsypilot']),
        autopsyStatus: _safeString(json['autopsystatus']),
        autopsyComments: _safeString(json['autopsycomments']),
        autopsyTtlp: _safeString(json['autopsyttlp']),
        autopsyTtllpppTest: _safeString(json['autopsyttllppptest']),
        buildingId: _safeString(json['building_id']),
        autopsyCustomerName: _safeString(json['autopsycustomername']),
        type: _safeString(json['type']),
        adminAutopsyName: _safeString(json['adminautopsyname']),
        autopsyAdminLandline: _safeString(json['autopsyadminlandline']),
        technicalCheckStatus: _safeString(json['technicalcheckstatus']),
        soilWorkStatus: _safeString(json['soilworkstatus']),
        constructionStatus: _safeString(json['constructionstatus']),
        splicingStatus: _safeString(json['splicingstatus']),
        billingStatus: _safeString(json['billingstatus']),
        malfunctionStatus: _safeString(json['malfunctionstatus']),
      );
    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR: Failed to parse CAutopsy from JSON: $e');
      print('📋 Stack trace: $stackTrace');
      print('📋 JSON keys: ${json.keys.toList()}');
      
      // Create a minimal valid object to prevent total crash
      return CAutopsy(
        id: json['id']?.toString() ?? 'unknown',
        name: json['name']?.toString() ?? 'Unknown Autopsy',
      );
    }
  }

  Map<String, dynamic> toJson() => _$CAutopsyToJson(this);

  // SAFE CONVERSION HELPERS - Handle all API data type inconsistencies
  
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    return value.toString();
  }

  static bool? _safeBool(dynamic value) {
    if (value == null) return null;
    
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value == 1; // 1 = true, 0 = false
    } else if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower.isEmpty) return null;
      return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on';
    }
    
    return false;
  }

  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    } else if (value is double) {
      return value.toInt();
    }
    
    return null;
  }

  static DateTime? _safeDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
    } catch (e) {
      print('⚠️ Failed to parse DateTime: $value');
    }
    
    return null;
  }

  // UTILITY METHODS
  
  String get displayName => name ?? 'Autopsy ${id.substring(0, 8)}';
  
  String get fullAddress {
    final parts = <String>[];
    if (autopsyStreet?.isNotEmpty == true) parts.add(autopsyStreet!);
    if (autopsyCity?.isNotEmpty == true) parts.add(autopsyCity!);
    if (autopsyPostalCode?.isNotEmpty == true) parts.add(autopsyPostalCode!);
    return parts.isNotEmpty ? parts.join(', ') : (autopsyFullAddress ?? 'No address');
  }
  
  bool get isDeleted => deleted == true;
  bool get isOutOfSystem => autopsyOutOfSystem == true;
  
  // Copy with method for updates
  CAutopsy copyWith({
    String? id,
    String? name,
    bool? deleted,
    String? description,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? createdById,
    String? modifiedById,
    String? assignedUserId,
    String? tenantId,
    DateTime? streamUpdatedAt,
    int? versionNumber,
    String? autopsyFullAddress,
    String? autopsyStreet,
    String? autopsyPostalCode,
    String? autopsyMunicipality,
    String? autopsyState,
    String? autopsyCity,
    String? autopsyAge,
    String? autopsyAk,
    String? autopsyAdminEmail,
    String? autopsyAdminMobile,
    String? autopsyLandlinePhoneNumber,
    String? autopsyBid,
    String? autopsyCab,
    String? autopsyCategory,
    String? autopsyCustomerEmail,
    String? autopsyCustomerMobile,
    bool? autopsyOutOfSystem,
    String? autopsyCustomerFloor,
    String? autopsyLatitude,
    String? autopsyLongitude,
    String? autopsyOrderNumber,
    String? autopsyPilot,
    String? autopsyStatus,
    String? autopsyComments,
    String? autopsyTtlp,
    String? autopsyTtllpppTest,
    String? buildingId,
    String? autopsyCustomerName,
    String? type,
    String? adminAutopsyName,
    String? autopsyAdminLandline,
    String? technicalCheckStatus,
    String? soilWorkStatus,
    String? constructionStatus,
    String? splicingStatus,
    String? billingStatus,
    String? malfunctionStatus,
  }) {
    return CAutopsy(
      id: id ?? this.id,
      name: name ?? this.name,
      deleted: deleted ?? this.deleted,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdById: createdById ?? this.createdById,
      modifiedById: modifiedById ?? this.modifiedById,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      tenantId: tenantId ?? this.tenantId,
      streamUpdatedAt: streamUpdatedAt ?? this.streamUpdatedAt,
      versionNumber: versionNumber ?? this.versionNumber,
      autopsyFullAddress: autopsyFullAddress ?? this.autopsyFullAddress,
      autopsyStreet: autopsyStreet ?? this.autopsyStreet,
      autopsyPostalCode: autopsyPostalCode ?? this.autopsyPostalCode,
      autopsyMunicipality: autopsyMunicipality ?? this.autopsyMunicipality,
      autopsyState: autopsyState ?? this.autopsyState,
      autopsyCity: autopsyCity ?? this.autopsyCity,
      autopsyAge: autopsyAge ?? this.autopsyAge,
      autopsyAk: autopsyAk ?? this.autopsyAk,
      autopsyAdminEmail: autopsyAdminEmail ?? this.autopsyAdminEmail,
      autopsyAdminMobile: autopsyAdminMobile ?? this.autopsyAdminMobile,
      autopsyLandlinePhoneNumber: autopsyLandlinePhoneNumber ?? this.autopsyLandlinePhoneNumber,
      autopsyBid: autopsyBid ?? this.autopsyBid,
      autopsyCab: autopsyCab ?? this.autopsyCab,
      autopsyCategory: autopsyCategory ?? this.autopsyCategory,
      autopsyCustomerEmail: autopsyCustomerEmail ?? this.autopsyCustomerEmail,
      autopsyCustomerMobile: autopsyCustomerMobile ?? this.autopsyCustomerMobile,
      autopsyOutOfSystem: autopsyOutOfSystem ?? this.autopsyOutOfSystem,
      autopsyCustomerFloor: autopsyCustomerFloor ?? this.autopsyCustomerFloor,
      autopsyLatitude: autopsyLatitude ?? this.autopsyLatitude,
      autopsyLongitude: autopsyLongitude ?? this.autopsyLongitude,
      autopsyOrderNumber: autopsyOrderNumber ?? this.autopsyOrderNumber,
      autopsyPilot: autopsyPilot ?? this.autopsyPilot,
      autopsyStatus: autopsyStatus ?? this.autopsyStatus,
      autopsyComments: autopsyComments ?? this.autopsyComments,
      autopsyTtlp: autopsyTtlp ?? this.autopsyTtlp,
      autopsyTtllpppTest: autopsyTtllpppTest ?? this.autopsyTtllpppTest,
      buildingId: buildingId ?? this.buildingId,
      autopsyCustomerName: autopsyCustomerName ?? this.autopsyCustomerName,
      type: type ?? this.type,
      adminAutopsyName: adminAutopsyName ?? this.adminAutopsyName,
      autopsyAdminLandline: autopsyAdminLandline ?? this.autopsyAdminLandline,
      technicalCheckStatus: technicalCheckStatus ?? this.technicalCheckStatus,
      soilWorkStatus: soilWorkStatus ?? this.soilWorkStatus,
      constructionStatus: constructionStatus ?? this.constructionStatus,
      splicingStatus: splicingStatus ?? this.splicingStatus,
      billingStatus: billingStatus ?? this.billingStatus,
      malfunctionStatus: malfunctionStatus ?? this.malfunctionStatus,
    );
  }
}

// Request Models
@JsonSerializable()
class CreateAutopsyRequest {
  final String? name;
  final String? description;
  @JsonKey(name: 'autopsyfulladdress')
  final String? autopsyFullAddress;
  @JsonKey(name: 'autopsystreet')
  final String? autopsyStreet;
  @JsonKey(name: 'autopsypostalcode')
  final String? autopsyPostalCode;
  @JsonKey(name: 'autopsymunicipality')
  final String? autopsyMunicipality;
  @JsonKey(name: 'autopsystate')
  final String? autopsyState;
  @JsonKey(name: 'autopsycity')
  final String? autopsyCity;
  @JsonKey(name: 'autopsycustomername')
  final String? autopsyCustomerName;
  @JsonKey(name: 'autopsycustomeremail')
  final String? autopsyCustomerEmail;
  @JsonKey(name: 'autopsycustomermobile')
  final String? autopsyCustomerMobile;
  @JsonKey(name: 'autopsystatus')
  final String? autopsyStatus;
  @JsonKey(name: 'autopsycategory')
  final String? autopsyCategory;
  @JsonKey(name: 'autopsycomments')
  final String? autopsyComments;
  @JsonKey(name: 'technicalcheckstatus')
  final String? technicalCheckStatus;
  @JsonKey(name: 'assigned_user_id')
  final String? assignedUserId;

  const CreateAutopsyRequest({
    this.name,
    this.description,
    this.autopsyFullAddress,
    this.autopsyStreet,
    this.autopsyPostalCode,
    this.autopsyMunicipality,
    this.autopsyState,
    this.autopsyCity,
    this.autopsyCustomerName,
    this.autopsyCustomerEmail,
    this.autopsyCustomerMobile,
    this.autopsyStatus,
    this.autopsyCategory,
    this.autopsyComments,
    this.technicalCheckStatus,
    this.assignedUserId,
  });

  factory CreateAutopsyRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateAutopsyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAutopsyRequestToJson(this);
}

@JsonSerializable()
class UpdateAutopsyRequest {
  final String? name;
  final String? description;
  @JsonKey(name: 'autopsyfulladdress')
  final String? autopsyFullAddress;
  @JsonKey(name: 'autopsystatus')
  final String? autopsyStatus;
  @JsonKey(name: 'autopsycomments')
  final String? autopsyComments;
  @JsonKey(name: 'technicalcheckstatus')
  final String? technicalCheckStatus;
  @JsonKey(name: 'autopsycustomermobile')
  final String? autopsyCustomerMobile;

  const UpdateAutopsyRequest({
    this.name,
    this.description,
    this.autopsyFullAddress,
    this.autopsyStatus,
    this.autopsyComments,
    this.technicalCheckStatus,
    this.autopsyCustomerMobile,
  });

  factory UpdateAutopsyRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateAutopsyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateAutopsyRequestToJson(this);
}

// FIXED: Single unified response model - use this everywhere
@JsonSerializable()
class AutopsyResponse {
  final List<CAutopsy> data;
  final int total;
  final int limit;
  final int offset;
  @JsonKey(name: 'total_active')
  final int? totalActive;
  @JsonKey(name: 'total_deleted')
  final int? totalDeleted;

  const AutopsyResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
    this.totalActive,
    this.totalDeleted,
  });

  factory AutopsyResponse.fromJson(Map<String, dynamic> json) => 
      _$AutopsyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyResponseToJson(this);
}

@JsonSerializable()
class AutopsyDetailResponse {
  final CAutopsy? data;
  @JsonKey(name: 'permission_denied')
  final bool? permissionDenied;

  const AutopsyDetailResponse({
    this.data,
    this.permissionDenied,
  });

  factory AutopsyDetailResponse.fromJson(Map<String, dynamic> json) => 
      _$AutopsyDetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyDetailResponseToJson(this);
}

// Permissions Models
@JsonSerializable()
class AutopsyPermissions {
  @JsonKey(name: 'can_create')
  final bool canCreate;
  @JsonKey(name: 'can_read')
  final bool canRead;
  @JsonKey(name: 'can_edit')
  final bool canEdit;
  @JsonKey(name: 'can_delete')
  final bool canDelete;
  @JsonKey(name: 'can_restore')
  final bool canRestore;
  @JsonKey(name: 'can_permanent_delete')
  final bool canPermanentDelete;
  @JsonKey(name: 'can_view_deleted')
  final bool canViewDeleted;
  @JsonKey(name: 'visible_fields')
  final List<String> visibleFields;
  @JsonKey(name: 'editable_fields')
  final List<String> editableFields;
  @JsonKey(name: 'creatable_fields')
  final List<String> creatableFields;

  const AutopsyPermissions({
    required this.canCreate,
    required this.canRead,
    required this.canEdit,
    required this.canDelete,
    required this.canRestore,
    required this.canPermanentDelete,
    required this.canViewDeleted,
    required this.visibleFields,
    required this.editableFields,
    required this.creatableFields,
  });

  factory AutopsyPermissions.fromJson(Map<String, dynamic> json) => 
      _$AutopsyPermissionsFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyPermissionsToJson(this);

  // Default permissions for fallback
  factory AutopsyPermissions.defaultPermissions() {
    return const AutopsyPermissions(
      canCreate: false,
      canRead: true,
      canEdit: false,
      canDelete: false,
      canRestore: false,
      canPermanentDelete: false,
      canViewDeleted: false,
      visibleFields: [],
      editableFields: [],
      creatableFields: [],
    );
  }
}

@JsonSerializable()
class PermissionResponse {
  final bool success;
  final AutopsyPermissions permissions;
  final bool? cached;

  const PermissionResponse({
    required this.success,
    required this.permissions,
    this.cached,
  });

  factory PermissionResponse.fromJson(Map<String, dynamic> json) => 
      _$PermissionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionResponseToJson(this);
}

// Query Parameters
class ListAutopsyParams {
  final int? limit;
  final int? offset;
  final String? orderBy;
  final String? orderDirection;
  final String? search;
  final String? status;
  final String? category;
  final bool? includeDeleted;
  final bool? onlyDeleted;
  final String? deletedBy;
  final String? deletedAfter;
  final String? deletedBefore;

  const ListAutopsyParams({
    this.limit,
    this.offset,
    this.orderBy,
    this.orderDirection,
    this.search,
    this.status,
    this.category,
    this.includeDeleted,
    this.onlyDeleted,
    this.deletedBy,
    this.deletedAfter,
    this.deletedBefore,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
    if (orderBy != null) params['orderBy'] = orderBy!;
    if (orderDirection != null) params['orderDirection'] = orderDirection!;
    if (search != null) params['search'] = search!;
    if (status != null) params['status'] = status!;
    if (category != null) params['category'] = category!;
    if (includeDeleted != null) params['includeDeleted'] = includeDeleted.toString();
    if (onlyDeleted != null) params['onlyDeleted'] = onlyDeleted.toString();
    if (deletedBy != null) params['deletedBy'] = deletedBy!;
    if (deletedAfter != null) params['deletedAfter'] = deletedAfter!;
    if (deletedBefore != null) params['deletedBefore'] = deletedBefore!;
    
    return params;
  }

  // Add pagination methods for compatibility
  int get page => ((offset ?? 0) ~/ (limit ?? 20)) + 1;
  int get pageSize => limit ?? 20;
  
  ListAutopsyParams copyWith({
    int? limit,
    int? offset,
    String? orderBy,
    String? orderDirection,
    String? search,
    String? status,
    String? category,
    bool? includeDeleted,
    bool? onlyDeleted,
    String? deletedBy,
    String? deletedAfter,
    String? deletedBefore,
  }) {
    return ListAutopsyParams(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      orderBy: orderBy ?? this.orderBy,
      orderDirection: orderDirection ?? this.orderDirection,
      search: search ?? this.search,
      status: status ?? this.status,
      category: category ?? this.category,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      onlyDeleted: onlyDeleted ?? this.onlyDeleted,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAfter: deletedAfter ?? this.deletedAfter,
      deletedBefore: deletedBefore ?? this.deletedBefore,
    );
  }
}

class SearchAutopsyParams {
  final String query;
  final List<String>? fields;
  final int? limit;
  final bool? includeDeleted;

  const SearchAutopsyParams({
    required this.query,
    this.fields,
    this.limit,
    this.includeDeleted,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'query': query,
    };
    
    if (fields != null) params['fields'] = fields!.join(',');
    if (limit != null) params['limit'] = limit.toString();
    if (includeDeleted != null) params['includeDeleted'] = includeDeleted.toString();
    
    return params;
  }
}

// Status and Category Options
class AutopsyStatusOption {
  final String value;
  final String label;
  final String? color;
  final String? icon;

  const AutopsyStatusOption({
    required this.value,
    required this.label,
    this.color,
    this.icon,
  });
}

class AutopsyCategoryOption {
  final String value;
  final String label;

  const AutopsyCategoryOption({
    required this.value,
    required this.label,
  });
}

// Static Options
class AutopsyOptions {
  static const List<AutopsyStatusOption> statusOptions = [
    AutopsyStatusOption(value: 'new', label: 'Νέο', color: 'blue'),
    AutopsyStatusOption(value: 'autopsy_scheduled', label: 'Προγραμματισμένο', color: 'orange'),
    AutopsyStatusOption(value: 'autopsy_in_progress', label: 'Σε εξέλιξη', color: 'yellow'),
    AutopsyStatusOption(value: 'autopsy_completed', label: 'Ολοκληρωμένο', color: 'green'),
    AutopsyStatusOption(value: 'technical_check_pending', label: 'Εκκρεμεί έλεγχος', color: 'purple'),
    AutopsyStatusOption(value: 'technical_check_rejected', label: 'Απορρίφθηκε', color: 'red'),
    AutopsyStatusOption(value: 'technical_check_approved', label: 'Εγκρίθηκε', color: 'green'),
    AutopsyStatusOption(value: 'work_orders_created', label: 'Εντολές εργασίας', color: 'indigo'),
    AutopsyStatusOption(value: 'job_completed', label: 'Ολοκληρώθηκε', color: 'green'),
    AutopsyStatusOption(value: 'job_cancelled', label: 'Ακυρώθηκε', color: 'gray'),
  ];

  static const List<AutopsyCategoryOption> categoryOptions = [
    AutopsyCategoryOption(value: 'FTTH Retail', label: 'FTTH Retail'),
    AutopsyCategoryOption(value: 'FTTH Business', label: 'FTTH Business'),
    AutopsyCategoryOption(value: 'VDSL', label: 'VDSL'),
    AutopsyCategoryOption(value: 'ADSL', label: 'ADSL'),
    AutopsyCategoryOption(value: 'Other', label: 'Άλλο'),
  ];

  static AutopsyStatusOption? getStatusOption(String status) {
    try {
      return statusOptions.firstWhere((option) => option.value == status);
    } catch (_) {
      return null;
    }
  }

  static AutopsyCategoryOption? getCategoryOption(String category) {
    try {
      return categoryOptions.firstWhere((option) => option.value == category);
    } catch (_) {
      return null;
    }
  }
}

// Exception Classes
class AutopsyException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final Map<String, dynamic>? details;

  const AutopsyException({
    required this.message,
    this.statusCode,
    this.originalError,
    this.details,
  });

  @override
  String toString() => 'AutopsyException: $message';
}

class AutopsyPermissionException extends AutopsyException {
  const AutopsyPermissionException({
    required super.message,
    super.statusCode,
    super.originalError,
    super.details,
  });

  @override
  String toString() => 'AutopsyPermissionException: $message';
}

class AutopsyNotFoundException extends AutopsyException {
  const AutopsyNotFoundException({
    required super.message,
    super.statusCode,
    super.originalError,
    super.details,
  });

  @override
  String toString() => 'AutopsyNotFoundException: $message';
}

class AutopsyDataException extends AutopsyException {
  final String? fieldName;
  final dynamic receivedValue;
  final Type? expectedType;

  const AutopsyDataException({
    required super.message,
    super.statusCode,
    super.originalError,
    super.details,
    this.fieldName,
    this.receivedValue,
    this.expectedType,
  });

  @override
  String toString() => 'AutopsyDataException: $message';
}

// FIXED: Remove the duplicate ListAutopsyResponse - use AutopsyResponse everywhere
// If you need a simplified version, create a helper method like:
extension AutopsyResponseExtensions on AutopsyResponse {
  /// Convert to simplified list response format
  Map<String, dynamic> toSimpleResponse() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}