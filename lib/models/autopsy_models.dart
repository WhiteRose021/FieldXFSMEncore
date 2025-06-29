// lib/models/autopsy_models.dart - CLEANED VERSION
// Following FSM Architecture PLAN - Fixed duplicates and DateTime issues

import 'package:json_annotation/json_annotation.dart';

part 'autopsy_models.g.dart';

// ============= MAIN AUTOPSY MODEL =============

@JsonSerializable()
class CAutopsy {
  final String id;
  final String? name;
  final String? displayName;
  final String? description;
  final bool? deleted;
  final String? createdAt;           // Changed: DateTime → String
  final String? modifiedAt;          // Changed: DateTime → String  
  final String? deletedAt;           // Changed: DateTime → String
  final String? createdById;
  final String? modifiedById;
  final String? assignedUserId;
  final String? tenantId;
  final String? streamUpdatedAt;     // Changed: DateTime → String
  final int? versionNumber;
  final bool? isDeleted;
  
  // Address fields - cleaned duplicates
  final String? autopsyFullAddress;
  final String? autopsyStreet;
  final String? autopsyPostalCode;
  final String? autopsyMunicipality;
  final String? autopsyState;
  final String? autopsyCity;
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;
  
  // Customer fields - removed duplicates
  final String? autopsyCustomerName;      // Removed: autopsycustomername
  final String? autopsyCustomerEmail;     // Removed: autopsycustomeremail
  final String? autopsyCustomerMobile;    // Removed: autopsycustomermobile
  final String? autopsyCustomerFloor;
  
  // Contact fields
  final String? autopsyAge;
  final String? autopsyAk;
  final String? autopsyAdminEmail;
  final String? autopsyAdminMobile;
  final String? autopsyLandlinePhoneNumber;
  final String? autopsyAdminLandline;
  final String? adminAutopsyName;
  
  // Business fields - removed duplicates
  final String? autopsyBid;              // Removed: autopsybid
  final String? autopsyCab;              // Removed: autopsycab
  final String? autopsyCategory;         // Removed: autopsycategory
  final String? autopsyOrderNumber;      // Removed: autopsyordernumber
  final String? autopsyPilot;
  final String? type;
  
  // Status fields - removed duplicates
  final String? autopsyStatus;           // Removed: autopsystatus
  final String? technicalCheckStatus;    // Removed: technicalcheckstatus
  final String? soilWorkStatus;
  final String? constructionStatus;
  final String? splicingStatus;
  final String? billingStatus;
  final String? malfunctionStatus;
  
  // Additional fields - removed duplicates
  final String? autopsyComments;         // Removed: autopsycomments
  final String? autopsyOutOfSystem;
  final double? autopsyLatitude;
  final double? autopsyLongitude;
  final String? autopsyTtlp;
  final String? autopsyTtllpppTest;
  final String? buildingId;

  CAutopsy({
    required this.id,
    this.name,
    this.displayName,
    this.description,
    this.deleted,
    this.createdAt,
    this.modifiedAt,
    this.deletedAt,
    this.createdById,
    this.modifiedById,
    this.assignedUserId,
    this.tenantId,
    this.streamUpdatedAt,
    this.versionNumber,
    this.isDeleted,
    this.autopsyFullAddress,
    this.autopsyStreet,
    this.autopsyPostalCode,
    this.autopsyMunicipality,
    this.autopsyState,
    this.autopsyCity,
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.postcode,
    this.country,
    this.autopsyCustomerName,
    this.autopsyCustomerEmail,
    this.autopsyCustomerMobile,
    this.autopsyCustomerFloor,
    this.autopsyAge,
    this.autopsyAk,
    this.autopsyAdminEmail,
    this.autopsyAdminMobile,
    this.autopsyLandlinePhoneNumber,
    this.autopsyAdminLandline,
    this.adminAutopsyName,
    this.autopsyBid,
    this.autopsyCab,
    this.autopsyCategory,
    this.autopsyOrderNumber,
    this.autopsyPilot,
    this.type,
    this.autopsyStatus,
    this.technicalCheckStatus,
    this.soilWorkStatus,
    this.constructionStatus,
    this.splicingStatus,
    this.billingStatus,
    this.malfunctionStatus,
    this.autopsyComments,
    this.autopsyOutOfSystem,
    this.autopsyLatitude,
    this.autopsyLongitude,
    this.autopsyTtlp,
    this.autopsyTtllpppTest,
    this.buildingId,
  });

  factory CAutopsy.fromJson(Map<String, dynamic> json) => _$CAutopsyFromJson(json);
  Map<String, dynamic> toJson() => _$CAutopsyToJson(this);

  // Computed properties - updated for cleaned fields
  String get fullAddress {
    if (autopsyFullAddress?.isNotEmpty == true) return autopsyFullAddress!;
    
    final parts = <String>[];
    if (address1?.isNotEmpty == true) parts.add(address1!);
    if (address2?.isNotEmpty == true) parts.add(address2!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (postcode?.isNotEmpty == true) parts.add(postcode!);
    return parts.join(', ');
  }

  String get statusDisplayName {
    return AutopsyOptions.getStatusLabel(autopsyStatus) ?? 
           autopsyStatus ?? 'Unknown';
  }

  String get categoryDisplayName {
    return AutopsyOptions.getCategoryLabel(autopsyCategory) ?? 
           autopsyCategory ?? 'Unknown';
  }

  bool get isActive => deleted != true && isDeleted != true;

  String get effectiveDisplayName {
    return displayName ?? name ?? autopsyCustomerName ?? 'Autopsy $id';
  }

  // Simplified copyWith method (much shorter now!)
  CAutopsy copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    bool? deleted,
    String? createdAt,
    String? modifiedAt,
    String? deletedAt,
    String? createdById,
    String? modifiedById,
    String? assignedUserId,
    String? tenantId,
    String? streamUpdatedAt,
    int? versionNumber,
    bool? isDeleted,
    String? autopsyFullAddress,
    String? autopsyStreet,
    String? autopsyPostalCode,
    String? autopsyMunicipality,
    String? autopsyState,
    String? autopsyCity,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? postcode,
    String? country,
    String? autopsyCustomerName,
    String? autopsyCustomerEmail,
    String? autopsyCustomerMobile,
    String? autopsyCustomerFloor,
    String? autopsyAge,
    String? autopsyAk,
    String? autopsyAdminEmail,
    String? autopsyAdminMobile,
    String? autopsyLandlinePhoneNumber,
    String? autopsyAdminLandline,
    String? adminAutopsyName,
    String? autopsyBid,
    String? autopsyCab,
    String? autopsyCategory,
    String? autopsyOrderNumber,
    String? autopsyPilot,
    String? type,
    String? autopsyStatus,
    String? technicalCheckStatus,
    String? soilWorkStatus,
    String? constructionStatus,
    String? splicingStatus,
    String? billingStatus,
    String? malfunctionStatus,
    String? autopsyComments,
    String? autopsyOutOfSystem,
    double? autopsyLatitude,
    double? autopsyLongitude,
    String? autopsyTtlp,
    String? autopsyTtllpppTest,
    String? buildingId,
  }) {
    return CAutopsy(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdById: createdById ?? this.createdById,
      modifiedById: modifiedById ?? this.modifiedById,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      tenantId: tenantId ?? this.tenantId,
      streamUpdatedAt: streamUpdatedAt ?? this.streamUpdatedAt,
      versionNumber: versionNumber ?? this.versionNumber,
      isDeleted: isDeleted ?? this.isDeleted,
      autopsyFullAddress: autopsyFullAddress ?? this.autopsyFullAddress,
      autopsyStreet: autopsyStreet ?? this.autopsyStreet,
      autopsyPostalCode: autopsyPostalCode ?? this.autopsyPostalCode,
      autopsyMunicipality: autopsyMunicipality ?? this.autopsyMunicipality,
      autopsyState: autopsyState ?? this.autopsyState,
      autopsyCity: autopsyCity ?? this.autopsyCity,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      autopsyCustomerName: autopsyCustomerName ?? this.autopsyCustomerName,
      autopsyCustomerEmail: autopsyCustomerEmail ?? this.autopsyCustomerEmail,
      autopsyCustomerMobile: autopsyCustomerMobile ?? this.autopsyCustomerMobile,
      autopsyCustomerFloor: autopsyCustomerFloor ?? this.autopsyCustomerFloor,
      autopsyAge: autopsyAge ?? this.autopsyAge,
      autopsyAk: autopsyAk ?? this.autopsyAk,
      autopsyAdminEmail: autopsyAdminEmail ?? this.autopsyAdminEmail,
      autopsyAdminMobile: autopsyAdminMobile ?? this.autopsyAdminMobile,
      autopsyLandlinePhoneNumber: autopsyLandlinePhoneNumber ?? this.autopsyLandlinePhoneNumber,
      autopsyAdminLandline: autopsyAdminLandline ?? this.autopsyAdminLandline,
      adminAutopsyName: adminAutopsyName ?? this.adminAutopsyName,
      autopsyBid: autopsyBid ?? this.autopsyBid,
      autopsyCab: autopsyCab ?? this.autopsyCab,
      autopsyCategory: autopsyCategory ?? this.autopsyCategory,
      autopsyOrderNumber: autopsyOrderNumber ?? this.autopsyOrderNumber,
      autopsyPilot: autopsyPilot ?? this.autopsyPilot,
      type: type ?? this.type,
      autopsyStatus: autopsyStatus ?? this.autopsyStatus,
      technicalCheckStatus: technicalCheckStatus ?? this.technicalCheckStatus,
      soilWorkStatus: soilWorkStatus ?? this.soilWorkStatus,
      constructionStatus: constructionStatus ?? this.constructionStatus,
      splicingStatus: splicingStatus ?? this.splicingStatus,
      billingStatus: billingStatus ?? this.billingStatus,
      malfunctionStatus: malfunctionStatus ?? this.malfunctionStatus,
      autopsyComments: autopsyComments ?? this.autopsyComments,
      autopsyOutOfSystem: autopsyOutOfSystem ?? this.autopsyOutOfSystem,
      autopsyLatitude: autopsyLatitude ?? this.autopsyLatitude,
      autopsyLongitude: autopsyLongitude ?? this.autopsyLongitude,
      autopsyTtlp: autopsyTtlp ?? this.autopsyTtlp,
      autopsyTtllpppTest: autopsyTtllpppTest ?? this.autopsyTtllpppTest,
      buildingId: buildingId ?? this.buildingId,
    );
  }
}

// ============= RESPONSE MODELS =============

@JsonSerializable()
class AutopsyResponse {
  final List<CAutopsy> data;
  final int total;
  final int? page;
  final int? limit;
  final int? offset;
  final int? totalActive;
  final int? totalDeleted;
  final bool? permissionDenied;
  final String? error;

  AutopsyResponse({
    required this.data,
    required this.total,
    this.page,
    this.limit,
    this.offset,
    this.totalActive,
    this.totalDeleted,
    this.permissionDenied,
    this.error,
  });

  factory AutopsyResponse.fromJson(Map<String, dynamic> json) => _$AutopsyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyResponseToJson(this);
}

@JsonSerializable()
class AutopsyListResponse {
  final List<CAutopsy> data;
  final int total;
  final int? page;
  final int? limit;
  final int? offset;
  final bool? permissionDenied;
  final String? error;

  AutopsyListResponse({
    required this.data,
    required this.total,
    this.page,
    this.limit,
    this.offset,
    this.permissionDenied,
    this.error,
  });

  factory AutopsyListResponse.fromJson(Map<String, dynamic> json) => _$AutopsyListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyListResponseToJson(this);
}

@JsonSerializable()
class AutopsyDetailResponse {
  final CAutopsy? data;
  final bool? permissionDenied;
  final String? error;

  AutopsyDetailResponse({
    this.data,
    this.permissionDenied,
    this.error,
  });

  factory AutopsyDetailResponse.fromJson(Map<String, dynamic> json) => _$AutopsyDetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyDetailResponseToJson(this);
}

@JsonSerializable()
class SingleAutopsyResponse {
  final CAutopsy? data;
  final bool? permissionDenied;
  final String? error;

  SingleAutopsyResponse({
    this.data,
    this.permissionDenied,
    this.error,
  });

  factory SingleAutopsyResponse.fromJson(Map<String, dynamic> json) => _$SingleAutopsyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SingleAutopsyResponseToJson(this);
}

// ============= REQUEST MODELS =============

@JsonSerializable()
class ListAutopsyParams {
  final int? limit;
  final int? offset;
  final String? orderBy;
  final String? orderDirection;
  final String? search;
  final String? status;
  final String? category;
  final bool? includeDeleted;

  ListAutopsyParams({
    this.limit,
    this.offset,
    this.orderBy,
    this.orderDirection,
    this.search,
    this.status,
    this.category,
    this.includeDeleted,
  });

  factory ListAutopsyParams.fromJson(Map<String, dynamic> json) => _$ListAutopsyParamsFromJson(json);
  Map<String, dynamic> toJson() => _$ListAutopsyParamsToJson(this);
}

@JsonSerializable()
class SearchAutopsyParams {
  final String query;
  final int? limit;
  final int? offset;

  SearchAutopsyParams({
    required this.query,
    this.limit,
    this.offset,
  });

  factory SearchAutopsyParams.fromJson(Map<String, dynamic> json) => _$SearchAutopsyParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SearchAutopsyParamsToJson(this);
}

@JsonSerializable()
class CreateAutopsyRequest {
  final String? name;
  final String? description;
  final String? displayName;
  final String? autopsyFullAddress;
  final String? autopsyStreet;
  final String? autopsyPostalCode;
  final String? autopsyMunicipality;
  final String? autopsyState;
  final String? autopsyCity;
  final String? autopsyCustomerName;
  final String? autopsyCustomerEmail;
  final String? autopsyCustomerMobile;
  final String? autopsyStatus;
  final String? autopsyCategory;
  final String? autopsyComments;
  final String? technicalCheckStatus;
  final String? assignedUserId;
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;
  final String? autopsyOrderNumber;
  final String? autopsyBid;
  final String? autopsyCab;

  CreateAutopsyRequest({
    this.name,
    this.description,
    this.displayName,
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
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.postcode,
    this.country,
    this.autopsyOrderNumber,
    this.autopsyBid,
    this.autopsyCab,
  });

  factory CreateAutopsyRequest.fromJson(Map<String, dynamic> json) => _$CreateAutopsyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAutopsyRequestToJson(this);
}

@JsonSerializable()
class UpdateAutopsyRequest {
  final String? name;
  final String? description;
  final String? autopsyFullAddress;
  final String? autopsyStatus;
  final String? autopsyComments;
  final String? technicalCheckStatus;
  final String? autopsyCustomerMobile;
  final String? displayName;
  final String? autopsyCustomerName;
  final String? autopsyCustomerEmail;
  final String? autopsyOrderNumber;
  final String? autopsyBid;
  final String? autopsyCab;
  final String? autopsyCategory;
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  UpdateAutopsyRequest({
    this.name,
    this.description,
    this.autopsyFullAddress,
    this.autopsyStatus,
    this.autopsyComments,
    this.technicalCheckStatus,
    this.autopsyCustomerMobile,
    this.displayName,
    this.autopsyCustomerName,
    this.autopsyCustomerEmail,
    this.autopsyOrderNumber,
    this.autopsyBid,
    this.autopsyCab,
    this.autopsyCategory,
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  factory UpdateAutopsyRequest.fromJson(Map<String, dynamic> json) => _$UpdateAutopsyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateAutopsyRequestToJson(this);
}

// ============= PERMISSION MODELS =============

@JsonSerializable()
class AutopsyPermissions {
  final bool canRead;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canRestore;
  final bool canPermanentDelete;
  final bool canViewDeleted;
  final List<String> visibleFields;
  final List<String> editableFields;
  final List<String> creatableFields;

  AutopsyPermissions({
    required this.canRead,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.canRestore,
    required this.canPermanentDelete,
    required this.canViewDeleted,
    required this.visibleFields,
    required this.editableFields,
    required this.creatableFields,
  });

  factory AutopsyPermissions.fromJson(Map<String, dynamic> json) => _$AutopsyPermissionsFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyPermissionsToJson(this);

  static AutopsyPermissions get defaultPermissions => AutopsyPermissions(
    canRead: true,
    canCreate: false,
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

@JsonSerializable()
class PermissionResponse {
  final AutopsyPermissions? data;
  final String? error;

  PermissionResponse({
    this.data,
    this.error,
  });

  factory PermissionResponse.fromJson(Map<String, dynamic> json) => _$PermissionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionResponseToJson(this);
}

// ============= OPTION MODELS =============

@JsonSerializable()
class AutopsyStatusOption {
  final String value;
  final String label;
  final String? color;
  final int? order;

  AutopsyStatusOption({
    required this.value,
    required this.label,
    this.color,
    this.order,
  });

  factory AutopsyStatusOption.fromJson(Map<String, dynamic> json) => _$AutopsyStatusOptionFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyStatusOptionToJson(this);
}

@JsonSerializable()
class AutopsyCategoryOption {
  final String value;
  final String label;
  final String? description;
  final int? order;

  AutopsyCategoryOption({
    required this.value,
    required this.label,
    this.description,
    this.order,
  });

  factory AutopsyCategoryOption.fromJson(Map<String, dynamic> json) => _$AutopsyCategoryOptionFromJson(json);
  Map<String, dynamic> toJson() => _$AutopsyCategoryOptionToJson(this);
}

// ============= OPTIONS HELPER CLASS =============

class AutopsyOptions {
  static final List<AutopsyStatusOption> statusOptions = [
    AutopsyStatusOption(value: 'new', label: 'New', color: '#2196F3', order: 1),
    AutopsyStatusOption(value: 'autopsy_scheduled', label: 'Autopsy Scheduled', color: '#FF9800', order: 2),
    AutopsyStatusOption(value: 'autopsy_in_progress', label: 'Autopsy In Progress', color: '#FFC107', order: 3),
    AutopsyStatusOption(value: 'autopsy_completed', label: 'Autopsy Completed', color: '#4CAF50', order: 4),
    AutopsyStatusOption(value: 'technical_check_pending', label: 'Technical Check Pending', color: '#9C27B0', order: 5),
    AutopsyStatusOption(value: 'technical_check_rejected', label: 'Technical Check Rejected', color: '#F44336', order: 6),
    AutopsyStatusOption(value: 'technical_check_approved', label: 'Technical Check Approved', color: '#4CAF50', order: 7),
    AutopsyStatusOption(value: 'work_orders_created', label: 'Work Orders Created', color: '#3F51B5', order: 8),
    AutopsyStatusOption(value: 'job_completed', label: 'Job Completed', color: '#4CAF50', order: 9),
    AutopsyStatusOption(value: 'job_cancelled', label: 'Job Cancelled', color: '#9E9E9E', order: 10),
  ];

  static final List<AutopsyCategoryOption> categoryOptions = [
    AutopsyCategoryOption(value: 'residential', label: 'Residential', order: 1),
    AutopsyCategoryOption(value: 'commercial', label: 'Commercial', order: 2),
    AutopsyCategoryOption(value: 'industrial', label: 'Industrial', order: 3),
    AutopsyCategoryOption(value: 'emergency', label: 'Emergency', order: 4),
    AutopsyCategoryOption(value: 'maintenance', label: 'Maintenance', order: 5),
  ];

  static String? getStatusLabel(String? status) {
    if (status == null) return null;
    try {
      return statusOptions.firstWhere((option) => option.value == status).label;
    } catch (_) {
      return status;
    }
  }

  static String? getCategoryLabel(String? category) {
    if (category == null) return null;
    try {
      return categoryOptions.firstWhere((option) => option.value == category).label;
    } catch (_) {
      return category;
    }
  }

  static String? getStatusColor(String? status) {
    if (status == null) return null;
    try {
      return statusOptions.firstWhere((option) => option.value == status).color;
    } catch (_) {
      return '#9E9E9E';
    }
  }
}

// ============= EXCEPTION MODELS =============

class AutopsyException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AutopsyException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AutopsyException: $message';
}

class AutopsyNotFoundException extends AutopsyException {
  AutopsyNotFoundException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'not_found',
          originalError: originalError,
        );
}

class AutopsyPermissionException extends AutopsyException {
  AutopsyPermissionException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'permission_denied',
          originalError: originalError,
        );
}

class AutopsyValidationException extends AutopsyException {
  final Map<String, List<String>>? fieldErrors;

  AutopsyValidationException({
    required String message,
    this.fieldErrors,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'validation_error',
          originalError: originalError,
        );
}

class AutopsyNetworkException extends AutopsyException {
  final int? statusCode;

  AutopsyNetworkException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code ?? 'network_error',
          originalError: originalError,
        );
}