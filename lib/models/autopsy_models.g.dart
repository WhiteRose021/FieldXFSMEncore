// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autopsy_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CAutopsy _$CAutopsyFromJson(Map<String, dynamic> json) => CAutopsy(
      id: json['id'] as String,
      name: json['name'] as String?,
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      deleted: json['deleted'] as bool?,
      createdAt: json['createdAt'] as String?,
      modifiedAt: json['modifiedAt'] as String?,
      deletedAt: json['deletedAt'] as String?,
      createdById: json['createdById'] as String?,
      modifiedById: json['modifiedById'] as String?,
      assignedUserId: json['assignedUserId'] as String?,
      tenantId: json['tenantId'] as String?,
      streamUpdatedAt: json['streamUpdatedAt'] as String?,
      versionNumber: (json['versionNumber'] as num?)?.toInt(),
      isDeleted: json['isDeleted'] as bool?,
      autopsyFullAddress: json['autopsyFullAddress'] as String?,
      autopsyStreet: json['autopsyStreet'] as String?,
      autopsyPostalCode: json['autopsyPostalCode'] as String?,
      autopsyMunicipality: json['autopsyMunicipality'] as String?,
      autopsyState: json['autopsyState'] as String?,
      autopsyCity: json['autopsyCity'] as String?,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
      autopsyCustomerName: json['autopsyCustomerName'] as String?,
      autopsyCustomerEmail: json['autopsyCustomerEmail'] as String?,
      autopsyCustomerMobile: json['autopsyCustomerMobile'] as String?,
      autopsyCustomerFloor: json['autopsyCustomerFloor'] as String?,
      autopsyAge: json['autopsyAge'] as String?,
      autopsyAk: json['autopsyAk'] as String?,
      autopsyAdminEmail: json['autopsyAdminEmail'] as String?,
      autopsyAdminMobile: json['autopsyAdminMobile'] as String?,
      autopsyLandlinePhoneNumber: json['autopsyLandlinePhoneNumber'] as String?,
      autopsyAdminLandline: json['autopsyAdminLandline'] as String?,
      adminAutopsyName: json['adminAutopsyName'] as String?,
      autopsyBid: json['autopsyBid'] as String?,
      autopsyCab: json['autopsyCab'] as String?,
      autopsyCategory: json['autopsyCategory'] as String?,
      autopsyOrderNumber: json['autopsyOrderNumber'] as String?,
      autopsyPilot: json['autopsyPilot'] as String?,
      type: json['type'] as String?,
      autopsyStatus: json['autopsyStatus'] as String?,
      technicalCheckStatus: json['technicalCheckStatus'] as String?,
      soilWorkStatus: json['soilWorkStatus'] as String?,
      constructionStatus: json['constructionStatus'] as String?,
      splicingStatus: json['splicingStatus'] as String?,
      billingStatus: json['billingStatus'] as String?,
      malfunctionStatus: json['malfunctionStatus'] as String?,
      autopsyComments: json['autopsyComments'] as String?,
      autopsyOutOfSystem: json['autopsyOutOfSystem'] as String?,
      autopsyLatitude: (json['autopsyLatitude'] as num?)?.toDouble(),
      autopsyLongitude: (json['autopsyLongitude'] as num?)?.toDouble(),
      autopsyTtlp: json['autopsyTtlp'] as String?,
      autopsyTtllpppTest: json['autopsyTtllpppTest'] as String?,
      buildingId: json['buildingId'] as String?,
    );

Map<String, dynamic> _$CAutopsyToJson(CAutopsy instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'displayName': instance.displayName,
      'description': instance.description,
      'deleted': instance.deleted,
      'createdAt': instance.createdAt,
      'modifiedAt': instance.modifiedAt,
      'deletedAt': instance.deletedAt,
      'createdById': instance.createdById,
      'modifiedById': instance.modifiedById,
      'assignedUserId': instance.assignedUserId,
      'tenantId': instance.tenantId,
      'streamUpdatedAt': instance.streamUpdatedAt,
      'versionNumber': instance.versionNumber,
      'isDeleted': instance.isDeleted,
      'autopsyFullAddress': instance.autopsyFullAddress,
      'autopsyStreet': instance.autopsyStreet,
      'autopsyPostalCode': instance.autopsyPostalCode,
      'autopsyMunicipality': instance.autopsyMunicipality,
      'autopsyState': instance.autopsyState,
      'autopsyCity': instance.autopsyCity,
      'address1': instance.address1,
      'address2': instance.address2,
      'city': instance.city,
      'state': instance.state,
      'postcode': instance.postcode,
      'country': instance.country,
      'autopsyCustomerName': instance.autopsyCustomerName,
      'autopsyCustomerEmail': instance.autopsyCustomerEmail,
      'autopsyCustomerMobile': instance.autopsyCustomerMobile,
      'autopsyCustomerFloor': instance.autopsyCustomerFloor,
      'autopsyAge': instance.autopsyAge,
      'autopsyAk': instance.autopsyAk,
      'autopsyAdminEmail': instance.autopsyAdminEmail,
      'autopsyAdminMobile': instance.autopsyAdminMobile,
      'autopsyLandlinePhoneNumber': instance.autopsyLandlinePhoneNumber,
      'autopsyAdminLandline': instance.autopsyAdminLandline,
      'adminAutopsyName': instance.adminAutopsyName,
      'autopsyBid': instance.autopsyBid,
      'autopsyCab': instance.autopsyCab,
      'autopsyCategory': instance.autopsyCategory,
      'autopsyOrderNumber': instance.autopsyOrderNumber,
      'autopsyPilot': instance.autopsyPilot,
      'type': instance.type,
      'autopsyStatus': instance.autopsyStatus,
      'technicalCheckStatus': instance.technicalCheckStatus,
      'soilWorkStatus': instance.soilWorkStatus,
      'constructionStatus': instance.constructionStatus,
      'splicingStatus': instance.splicingStatus,
      'billingStatus': instance.billingStatus,
      'malfunctionStatus': instance.malfunctionStatus,
      'autopsyComments': instance.autopsyComments,
      'autopsyOutOfSystem': instance.autopsyOutOfSystem,
      'autopsyLatitude': instance.autopsyLatitude,
      'autopsyLongitude': instance.autopsyLongitude,
      'autopsyTtlp': instance.autopsyTtlp,
      'autopsyTtllpppTest': instance.autopsyTtllpppTest,
      'buildingId': instance.buildingId,
    };

AutopsyResponse _$AutopsyResponseFromJson(Map<String, dynamic> json) =>
    AutopsyResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => CAutopsy.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      totalActive: (json['totalActive'] as num?)?.toInt(),
      totalDeleted: (json['totalDeleted'] as num?)?.toInt(),
      permissionDenied: json['permissionDenied'] as bool?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$AutopsyResponseToJson(AutopsyResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'offset': instance.offset,
      'totalActive': instance.totalActive,
      'totalDeleted': instance.totalDeleted,
      'permissionDenied': instance.permissionDenied,
      'error': instance.error,
    };

AutopsyListResponse _$AutopsyListResponseFromJson(Map<String, dynamic> json) =>
    AutopsyListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => CAutopsy.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      permissionDenied: json['permissionDenied'] as bool?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$AutopsyListResponseToJson(
        AutopsyListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'offset': instance.offset,
      'permissionDenied': instance.permissionDenied,
      'error': instance.error,
    };

AutopsyDetailResponse _$AutopsyDetailResponseFromJson(
        Map<String, dynamic> json) =>
    AutopsyDetailResponse(
      data: json['data'] == null
          ? null
          : CAutopsy.fromJson(json['data'] as Map<String, dynamic>),
      permissionDenied: json['permissionDenied'] as bool?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$AutopsyDetailResponseToJson(
        AutopsyDetailResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'permissionDenied': instance.permissionDenied,
      'error': instance.error,
    };

SingleAutopsyResponse _$SingleAutopsyResponseFromJson(
        Map<String, dynamic> json) =>
    SingleAutopsyResponse(
      data: json['data'] == null
          ? null
          : CAutopsy.fromJson(json['data'] as Map<String, dynamic>),
      permissionDenied: json['permissionDenied'] as bool?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$SingleAutopsyResponseToJson(
        SingleAutopsyResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'permissionDenied': instance.permissionDenied,
      'error': instance.error,
    };

ListAutopsyParams _$ListAutopsyParamsFromJson(Map<String, dynamic> json) =>
    ListAutopsyParams(
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      orderBy: json['orderBy'] as String?,
      orderDirection: json['orderDirection'] as String?,
      search: json['search'] as String?,
      status: json['status'] as String?,
      category: json['category'] as String?,
      includeDeleted: json['includeDeleted'] as bool?,
    );

Map<String, dynamic> _$ListAutopsyParamsToJson(ListAutopsyParams instance) =>
    <String, dynamic>{
      'limit': instance.limit,
      'offset': instance.offset,
      'orderBy': instance.orderBy,
      'orderDirection': instance.orderDirection,
      'search': instance.search,
      'status': instance.status,
      'category': instance.category,
      'includeDeleted': instance.includeDeleted,
    };

SearchAutopsyParams _$SearchAutopsyParamsFromJson(Map<String, dynamic> json) =>
    SearchAutopsyParams(
      query: json['query'] as String,
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SearchAutopsyParamsToJson(
        SearchAutopsyParams instance) =>
    <String, dynamic>{
      'query': instance.query,
      'limit': instance.limit,
      'offset': instance.offset,
    };

CreateAutopsyRequest _$CreateAutopsyRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAutopsyRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      displayName: json['displayName'] as String?,
      autopsyFullAddress: json['autopsyFullAddress'] as String?,
      autopsyStreet: json['autopsyStreet'] as String?,
      autopsyPostalCode: json['autopsyPostalCode'] as String?,
      autopsyMunicipality: json['autopsyMunicipality'] as String?,
      autopsyState: json['autopsyState'] as String?,
      autopsyCity: json['autopsyCity'] as String?,
      autopsyCustomerName: json['autopsyCustomerName'] as String?,
      autopsyCustomerEmail: json['autopsyCustomerEmail'] as String?,
      autopsyCustomerMobile: json['autopsyCustomerMobile'] as String?,
      autopsyStatus: json['autopsyStatus'] as String?,
      autopsyCategory: json['autopsyCategory'] as String?,
      autopsyComments: json['autopsyComments'] as String?,
      technicalCheckStatus: json['technicalCheckStatus'] as String?,
      assignedUserId: json['assignedUserId'] as String?,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
      autopsyOrderNumber: json['autopsyOrderNumber'] as String?,
      autopsyBid: json['autopsyBid'] as String?,
      autopsyCab: json['autopsyCab'] as String?,
    );

Map<String, dynamic> _$CreateAutopsyRequestToJson(
        CreateAutopsyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'displayName': instance.displayName,
      'autopsyFullAddress': instance.autopsyFullAddress,
      'autopsyStreet': instance.autopsyStreet,
      'autopsyPostalCode': instance.autopsyPostalCode,
      'autopsyMunicipality': instance.autopsyMunicipality,
      'autopsyState': instance.autopsyState,
      'autopsyCity': instance.autopsyCity,
      'autopsyCustomerName': instance.autopsyCustomerName,
      'autopsyCustomerEmail': instance.autopsyCustomerEmail,
      'autopsyCustomerMobile': instance.autopsyCustomerMobile,
      'autopsyStatus': instance.autopsyStatus,
      'autopsyCategory': instance.autopsyCategory,
      'autopsyComments': instance.autopsyComments,
      'technicalCheckStatus': instance.technicalCheckStatus,
      'assignedUserId': instance.assignedUserId,
      'address1': instance.address1,
      'address2': instance.address2,
      'city': instance.city,
      'state': instance.state,
      'postcode': instance.postcode,
      'country': instance.country,
      'autopsyOrderNumber': instance.autopsyOrderNumber,
      'autopsyBid': instance.autopsyBid,
      'autopsyCab': instance.autopsyCab,
    };

UpdateAutopsyRequest _$UpdateAutopsyRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateAutopsyRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      autopsyFullAddress: json['autopsyFullAddress'] as String?,
      autopsyStatus: json['autopsyStatus'] as String?,
      autopsyComments: json['autopsyComments'] as String?,
      technicalCheckStatus: json['technicalCheckStatus'] as String?,
      autopsyCustomerMobile: json['autopsyCustomerMobile'] as String?,
      displayName: json['displayName'] as String?,
      autopsyCustomerName: json['autopsyCustomerName'] as String?,
      autopsyCustomerEmail: json['autopsyCustomerEmail'] as String?,
      autopsyOrderNumber: json['autopsyOrderNumber'] as String?,
      autopsyBid: json['autopsyBid'] as String?,
      autopsyCab: json['autopsyCab'] as String?,
      autopsyCategory: json['autopsyCategory'] as String?,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$UpdateAutopsyRequestToJson(
        UpdateAutopsyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'autopsyFullAddress': instance.autopsyFullAddress,
      'autopsyStatus': instance.autopsyStatus,
      'autopsyComments': instance.autopsyComments,
      'technicalCheckStatus': instance.technicalCheckStatus,
      'autopsyCustomerMobile': instance.autopsyCustomerMobile,
      'displayName': instance.displayName,
      'autopsyCustomerName': instance.autopsyCustomerName,
      'autopsyCustomerEmail': instance.autopsyCustomerEmail,
      'autopsyOrderNumber': instance.autopsyOrderNumber,
      'autopsyBid': instance.autopsyBid,
      'autopsyCab': instance.autopsyCab,
      'autopsyCategory': instance.autopsyCategory,
      'address1': instance.address1,
      'address2': instance.address2,
      'city': instance.city,
      'state': instance.state,
      'postcode': instance.postcode,
      'country': instance.country,
    };

AutopsyPermissions _$AutopsyPermissionsFromJson(Map<String, dynamic> json) =>
    AutopsyPermissions(
      canRead: json['canRead'] as bool,
      canCreate: json['canCreate'] as bool,
      canEdit: json['canEdit'] as bool,
      canDelete: json['canDelete'] as bool,
      canRestore: json['canRestore'] as bool,
      canPermanentDelete: json['canPermanentDelete'] as bool,
      canViewDeleted: json['canViewDeleted'] as bool,
      visibleFields: (json['visibleFields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      editableFields: (json['editableFields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      creatableFields: (json['creatableFields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AutopsyPermissionsToJson(AutopsyPermissions instance) =>
    <String, dynamic>{
      'canRead': instance.canRead,
      'canCreate': instance.canCreate,
      'canEdit': instance.canEdit,
      'canDelete': instance.canDelete,
      'canRestore': instance.canRestore,
      'canPermanentDelete': instance.canPermanentDelete,
      'canViewDeleted': instance.canViewDeleted,
      'visibleFields': instance.visibleFields,
      'editableFields': instance.editableFields,
      'creatableFields': instance.creatableFields,
    };

PermissionResponse _$PermissionResponseFromJson(Map<String, dynamic> json) =>
    PermissionResponse(
      data: json['data'] == null
          ? null
          : AutopsyPermissions.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PermissionResponseToJson(PermissionResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'error': instance.error,
    };

AutopsyStatusOption _$AutopsyStatusOptionFromJson(Map<String, dynamic> json) =>
    AutopsyStatusOption(
      value: json['value'] as String,
      label: json['label'] as String,
      color: json['color'] as String?,
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AutopsyStatusOptionToJson(
        AutopsyStatusOption instance) =>
    <String, dynamic>{
      'value': instance.value,
      'label': instance.label,
      'color': instance.color,
      'order': instance.order,
    };

AutopsyCategoryOption _$AutopsyCategoryOptionFromJson(
        Map<String, dynamic> json) =>
    AutopsyCategoryOption(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AutopsyCategoryOptionToJson(
        AutopsyCategoryOption instance) =>
    <String, dynamic>{
      'value': instance.value,
      'label': instance.label,
      'description': instance.description,
      'order': instance.order,
    };
