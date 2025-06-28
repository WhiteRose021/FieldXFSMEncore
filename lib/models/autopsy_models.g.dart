// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autopsy_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CAutopsy _$CAutopsyFromJson(Map<String, dynamic> json) => CAutopsy(
      id: json['id'] as String,
      name: json['name'] as String?,
      deleted: json['deleted'] as bool?,
      description: json['description'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      modifiedAt: json['modified_at'] == null
          ? null
          : DateTime.parse(json['modified_at'] as String),
      createdById: json['created_by_id'] as String?,
      modifiedById: json['modified_by_id'] as String?,
      assignedUserId: json['assigned_user_id'] as String?,
      tenantId: json['tenant_id'] as String?,
      streamUpdatedAt: json['stream_updated_at'] == null
          ? null
          : DateTime.parse(json['stream_updated_at'] as String),
      versionNumber: (json['version_number'] as num?)?.toInt(),
      autopsyFullAddress: json['autopsyfulladdress'] as String?,
      autopsyStreet: json['autopsystreet'] as String?,
      autopsyPostalCode: json['autopsypostalcode'] as String?,
      autopsyMunicipality: json['autopsymunicipality'] as String?,
      autopsyState: json['autopsystate'] as String?,
      autopsyCity: json['autopsycity'] as String?,
      autopsyAge: json['autopsyage'] as String?,
      autopsyAk: json['autopsyak'] as String?,
      autopsyAdminEmail: json['autopsyadminemail'] as String?,
      autopsyAdminMobile: json['autopsyadminmobile'] as String?,
      autopsyLandlinePhoneNumber: json['autopsylandlinephonenumber'] as String?,
      autopsyBid: json['autopsybid'] as String?,
      autopsyCab: json['autopsycab'] as String?,
      autopsyCategory: json['autopsycategory'] as String?,
      autopsyCustomerEmail: json['autopsycustomeremail'] as String?,
      autopsyCustomerMobile: json['autopsycustomermobile'] as String?,
      autopsyOutOfSystem: json['autopsyoutofsystem'] as bool?,
      autopsyCustomerFloor: json['autopsycustomerfloor'] as String?,
      autopsyLatitude: json['autopsylatitude'] as String?,
      autopsyLongitude: json['autopsylongtitude'] as String?,
      autopsyOrderNumber: json['autopsyordernumber'] as String?,
      autopsyPilot: json['autopsypilot'] as String?,
      autopsyStatus: json['autopsystatus'] as String?,
      autopsyComments: json['autopsycomments'] as String?,
      autopsyTtlp: json['autopsyttlp'] as String?,
      autopsyTtllpppTest: json['autopsyttllppptest'] as String?,
      buildingId: json['building_id'] as String?,
      autopsyCustomerName: json['autopsycustomername'] as String?,
      type: json['type'] as String?,
      adminAutopsyName: json['adminautopsyname'] as String?,
      autopsyAdminLandline: json['autopsyadminlandline'] as String?,
      technicalCheckStatus: json['technicalcheckstatus'] as String?,
      soilWorkStatus: json['soilworkstatus'] as String?,
      constructionStatus: json['constructionstatus'] as String?,
      splicingStatus: json['splicingstatus'] as String?,
      billingStatus: json['billingstatus'] as String?,
      malfunctionStatus: json['malfunctionstatus'] as String?,
    );

Map<String, dynamic> _$CAutopsyToJson(CAutopsy instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'deleted': instance.deleted,
      'description': instance.description,
      'created_at': instance.createdAt?.toIso8601String(),
      'modified_at': instance.modifiedAt?.toIso8601String(),
      'created_by_id': instance.createdById,
      'modified_by_id': instance.modifiedById,
      'assigned_user_id': instance.assignedUserId,
      'tenant_id': instance.tenantId,
      'stream_updated_at': instance.streamUpdatedAt?.toIso8601String(),
      'version_number': instance.versionNumber,
      'autopsyfulladdress': instance.autopsyFullAddress,
      'autopsystreet': instance.autopsyStreet,
      'autopsypostalcode': instance.autopsyPostalCode,
      'autopsymunicipality': instance.autopsyMunicipality,
      'autopsystate': instance.autopsyState,
      'autopsycity': instance.autopsyCity,
      'autopsyage': instance.autopsyAge,
      'autopsyak': instance.autopsyAk,
      'autopsyadminemail': instance.autopsyAdminEmail,
      'autopsyadminmobile': instance.autopsyAdminMobile,
      'autopsylandlinephonenumber': instance.autopsyLandlinePhoneNumber,
      'autopsybid': instance.autopsyBid,
      'autopsycab': instance.autopsyCab,
      'autopsycategory': instance.autopsyCategory,
      'autopsycustomeremail': instance.autopsyCustomerEmail,
      'autopsycustomermobile': instance.autopsyCustomerMobile,
      'autopsyoutofsystem': instance.autopsyOutOfSystem,
      'autopsycustomerfloor': instance.autopsyCustomerFloor,
      'autopsylatitude': instance.autopsyLatitude,
      'autopsylongtitude': instance.autopsyLongitude,
      'autopsyordernumber': instance.autopsyOrderNumber,
      'autopsypilot': instance.autopsyPilot,
      'autopsystatus': instance.autopsyStatus,
      'autopsycomments': instance.autopsyComments,
      'autopsyttlp': instance.autopsyTtlp,
      'autopsyttllppptest': instance.autopsyTtllpppTest,
      'building_id': instance.buildingId,
      'autopsycustomername': instance.autopsyCustomerName,
      'type': instance.type,
      'adminautopsyname': instance.adminAutopsyName,
      'autopsyadminlandline': instance.autopsyAdminLandline,
      'technicalcheckstatus': instance.technicalCheckStatus,
      'soilworkstatus': instance.soilWorkStatus,
      'constructionstatus': instance.constructionStatus,
      'splicingstatus': instance.splicingStatus,
      'billingstatus': instance.billingStatus,
      'malfunctionstatus': instance.malfunctionStatus,
    };

CreateAutopsyRequest _$CreateAutopsyRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAutopsyRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      autopsyFullAddress: json['autopsyfulladdress'] as String?,
      autopsyStreet: json['autopsystreet'] as String?,
      autopsyPostalCode: json['autopsypostalcode'] as String?,
      autopsyMunicipality: json['autopsymunicipality'] as String?,
      autopsyState: json['autopsystate'] as String?,
      autopsyCity: json['autopsycity'] as String?,
      autopsyCustomerName: json['autopsycustomername'] as String?,
      autopsyCustomerEmail: json['autopsycustomeremail'] as String?,
      autopsyCustomerMobile: json['autopsycustomermobile'] as String?,
      autopsyStatus: json['autopsystatus'] as String?,
      autopsyCategory: json['autopsycategory'] as String?,
      autopsyComments: json['autopsycomments'] as String?,
      technicalCheckStatus: json['technicalcheckstatus'] as String?,
      assignedUserId: json['assigned_user_id'] as String?,
    );

Map<String, dynamic> _$CreateAutopsyRequestToJson(
        CreateAutopsyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'autopsyfulladdress': instance.autopsyFullAddress,
      'autopsystreet': instance.autopsyStreet,
      'autopsypostalcode': instance.autopsyPostalCode,
      'autopsymunicipality': instance.autopsyMunicipality,
      'autopsystate': instance.autopsyState,
      'autopsycity': instance.autopsyCity,
      'autopsycustomername': instance.autopsyCustomerName,
      'autopsycustomeremail': instance.autopsyCustomerEmail,
      'autopsycustomermobile': instance.autopsyCustomerMobile,
      'autopsystatus': instance.autopsyStatus,
      'autopsycategory': instance.autopsyCategory,
      'autopsycomments': instance.autopsyComments,
      'technicalcheckstatus': instance.technicalCheckStatus,
      'assigned_user_id': instance.assignedUserId,
    };

UpdateAutopsyRequest _$UpdateAutopsyRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateAutopsyRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      autopsyFullAddress: json['autopsyfulladdress'] as String?,
      autopsyStatus: json['autopsystatus'] as String?,
      autopsyComments: json['autopsycomments'] as String?,
      technicalCheckStatus: json['technicalcheckstatus'] as String?,
      autopsyCustomerMobile: json['autopsycustomermobile'] as String?,
    );

Map<String, dynamic> _$UpdateAutopsyRequestToJson(
        UpdateAutopsyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'autopsyfulladdress': instance.autopsyFullAddress,
      'autopsystatus': instance.autopsyStatus,
      'autopsycomments': instance.autopsyComments,
      'technicalcheckstatus': instance.technicalCheckStatus,
      'autopsycustomermobile': instance.autopsyCustomerMobile,
    };

AutopsyResponse _$AutopsyResponseFromJson(Map<String, dynamic> json) =>
    AutopsyResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => CAutopsy.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      totalActive: (json['total_active'] as num?)?.toInt(),
      totalDeleted: (json['total_deleted'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AutopsyResponseToJson(AutopsyResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
      'total_active': instance.totalActive,
      'total_deleted': instance.totalDeleted,
    };

AutopsyDetailResponse _$AutopsyDetailResponseFromJson(
        Map<String, dynamic> json) =>
    AutopsyDetailResponse(
      data: json['data'] == null
          ? null
          : CAutopsy.fromJson(json['data'] as Map<String, dynamic>),
      permissionDenied: json['permission_denied'] as bool?,
    );

Map<String, dynamic> _$AutopsyDetailResponseToJson(
        AutopsyDetailResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'permission_denied': instance.permissionDenied,
    };

AutopsyPermissions _$AutopsyPermissionsFromJson(Map<String, dynamic> json) =>
    AutopsyPermissions(
      canCreate: json['can_create'] as bool,
      canRead: json['can_read'] as bool,
      canEdit: json['can_edit'] as bool,
      canDelete: json['can_delete'] as bool,
      canRestore: json['can_restore'] as bool,
      canPermanentDelete: json['can_permanent_delete'] as bool,
      canViewDeleted: json['can_view_deleted'] as bool,
      visibleFields: (json['visible_fields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      editableFields: (json['editable_fields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      creatableFields: (json['creatable_fields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AutopsyPermissionsToJson(AutopsyPermissions instance) =>
    <String, dynamic>{
      'can_create': instance.canCreate,
      'can_read': instance.canRead,
      'can_edit': instance.canEdit,
      'can_delete': instance.canDelete,
      'can_restore': instance.canRestore,
      'can_permanent_delete': instance.canPermanentDelete,
      'can_view_deleted': instance.canViewDeleted,
      'visible_fields': instance.visibleFields,
      'editable_fields': instance.editableFields,
      'creatable_fields': instance.creatableFields,
    };

PermissionResponse _$PermissionResponseFromJson(Map<String, dynamic> json) =>
    PermissionResponse(
      success: json['success'] as bool,
      permissions: AutopsyPermissions.fromJson(
          json['permissions'] as Map<String, dynamic>),
      cached: json['cached'] as bool?,
    );

Map<String, dynamic> _$PermissionResponseToJson(PermissionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'permissions': instance.permissions,
      'cached': instance.cached,
    };
