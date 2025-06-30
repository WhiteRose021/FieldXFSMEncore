// lib/models/autopsy_models.dart - FIXED VERSION
// Addresses all compilation errors

import 'package:json_annotation/json_annotation.dart';

import '../utils/json_converters.dart';


part 'autopsy_models.g.dart';

// ============= MAIN AUTOPSY MODEL =============

@JsonSerializable()
class CAutopsy {
  final String id;
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
  final String? autopsyPilot;
  final String? type;
  final String? soilWorkStatus;
  final String? constructionStatus;
  final String? splicingStatus;
  final String? billingStatus;
  final String? malfunctionStatus;
  final bool? autopsyOutOfSystem;
  final double? autopsyLatitude;
  final double? autopsyLongitude;
  final String? autopsyTtlp;
  final String? autopsyTtllpppTest;
  final String? buildingId;
  @BoolFromIntConverter()
  final bool? deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  CAutopsy({
    required this.id,
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
    this.autopsyPilot,
    this.type,
    this.soilWorkStatus,
    this.constructionStatus,
    this.splicingStatus,
    this.billingStatus,
    this.malfunctionStatus,
    this.autopsyOutOfSystem,
    this.autopsyLatitude,
    this.autopsyLongitude,
    this.autopsyTtlp,
    this.autopsyTtllpppTest,
    this.buildingId,
    this.deleted,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory CAutopsy.fromJson(Map<String, dynamic> json) => _$CAutopsyFromJson(json);
  Map<String, dynamic> toJson() => _$CAutopsyToJson(this);

  // Helper methods
  String get effectiveDisplayName => displayName ?? name ?? autopsyCustomerName ?? 'Unnamed Autopsy';
  
  String get fullAddress {
    final addressParts = [
      autopsyFullAddress,
      autopsyStreet,
      autopsyCity,
      autopsyState,
      autopsyPostalCode,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return addressParts.join(', ');
  }

  CAutopsy copyWith({
    String? id,
    String? name,
    String? description,
    String? displayName,
    String? autopsyFullAddress,
    String? autopsyStreet,
    String? autopsyPostalCode,
    String? autopsyMunicipality,
    String? autopsyState,
    String? autopsyCity,
    String? autopsyCustomerName,
    String? autopsyCustomerEmail,
    String? autopsyCustomerMobile,
    String? autopsyStatus,
    String? autopsyCategory,
    String? autopsyComments,
    String? technicalCheckStatus,
    String? assignedUserId,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? postcode,
    String? country,
    String? autopsyOrderNumber,
    String? autopsyBid,
    String? autopsyCab,
    String? autopsyPilot,
    String? type,
    String? soilWorkStatus,
    String? constructionStatus,
    String? splicingStatus,
    String? billingStatus,
    String? malfunctionStatus,
    bool? autopsyOutOfSystem,
    double? autopsyLatitude,
    double? autopsyLongitude,
    String? autopsyTtlp,
    String? autopsyTtllpppTest,
    String? buildingId,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CAutopsy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      displayName: displayName ?? this.displayName,
      autopsyFullAddress: autopsyFullAddress ?? this.autopsyFullAddress,
      autopsyStreet: autopsyStreet ?? this.autopsyStreet,
      autopsyPostalCode: autopsyPostalCode ?? this.autopsyPostalCode,
      autopsyMunicipality: autopsyMunicipality ?? this.autopsyMunicipality,
      autopsyState: autopsyState ?? this.autopsyState,
      autopsyCity: autopsyCity ?? this.autopsyCity,
      autopsyCustomerName: autopsyCustomerName ?? this.autopsyCustomerName,
      autopsyCustomerEmail: autopsyCustomerEmail ?? this.autopsyCustomerEmail,
      autopsyCustomerMobile: autopsyCustomerMobile ?? this.autopsyCustomerMobile,
      autopsyStatus: autopsyStatus ?? this.autopsyStatus,
      autopsyCategory: autopsyCategory ?? this.autopsyCategory,
      autopsyComments: autopsyComments ?? this.autopsyComments,
      technicalCheckStatus: technicalCheckStatus ?? this.technicalCheckStatus,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      autopsyOrderNumber: autopsyOrderNumber ?? this.autopsyOrderNumber,
      autopsyBid: autopsyBid ?? this.autopsyBid,
      autopsyCab: autopsyCab ?? this.autopsyCab,
      autopsyPilot: autopsyPilot ?? this.autopsyPilot,
      type: type ?? this.type,
      soilWorkStatus: soilWorkStatus ?? this.soilWorkStatus,
      constructionStatus: constructionStatus ?? this.constructionStatus,
      splicingStatus: splicingStatus ?? this.splicingStatus,
      billingStatus: billingStatus ?? this.billingStatus,
      malfunctionStatus: malfunctionStatus ?? this.malfunctionStatus,
      autopsyOutOfSystem: autopsyOutOfSystem ?? this.autopsyOutOfSystem,
      autopsyLatitude: autopsyLatitude ?? this.autopsyLatitude,
      autopsyLongitude: autopsyLongitude ?? this.autopsyLongitude,
      autopsyTtlp: autopsyTtlp ?? this.autopsyTtlp,
      autopsyTtllpppTest: autopsyTtllpppTest ?? this.autopsyTtllpppTest,
      buildingId: buildingId ?? this.buildingId,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
  final bool? success; // FIXED: Added missing success parameter

  SingleAutopsyResponse({
    this.data,
    this.permissionDenied,
    this.error,
    this.success, // FIXED: Added success parameter
    String? message, // FIXED: Added optional message parameter
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
  final bool? onlyDeleted; // FIXED: Added missing onlyDeleted property

  ListAutopsyParams({
    this.limit,
    this.offset,
    this.orderBy,
    this.orderDirection,
    this.search,
    this.status,
    this.category,
    this.includeDeleted,
    this.onlyDeleted, // FIXED: Added onlyDeleted parameter
  });

  factory ListAutopsyParams.fromJson(Map<String, dynamic> json) => _$ListAutopsyParamsFromJson(json);
  Map<String, dynamic> toJson() => _$ListAutopsyParamsToJson(this);
}

@JsonSerializable()
class SearchAutopsyParams {
  final String query;
  final int? limit;
  final int? offset;
  final bool? includeDeleted; // FIXED: Added missing includeDeleted property

  SearchAutopsyParams({
    required this.query,
    this.limit,
    this.offset,
    this.includeDeleted, // FIXED: Added includeDeleted parameter
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
  final String? autopsyPilot;
  final String? type;

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
    this.autopsyPilot,
    this.type,
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
    AutopsyStatusOption(value: 'pending', label: 'Pending', color: '#FFA500', order: 1),
    AutopsyStatusOption(value: 'in_progress', label: 'In Progress', color: '#2196F3', order: 2),
    AutopsyStatusOption(value: 'completed', label: 'Completed', color: '#4CAF50', order: 3),
    AutopsyStatusOption(value: 'cancelled', label: 'Cancelled', color: '#F44336', order: 4),
    AutopsyStatusOption(value: 'on_hold', label: 'On Hold', color: '#9E9E9E', order: 5),
  ];

  static final List<AutopsyCategoryOption> categoryOptions = [
    AutopsyCategoryOption(value: 'new_installation', label: 'New Installation', order: 1),
    AutopsyCategoryOption(value: 'maintenance', label: 'Maintenance', order: 2),
    AutopsyCategoryOption(value: 'repair', label: 'Repair', order: 3),
    AutopsyCategoryOption(value: 'upgrade', label: 'Upgrade', order: 4),
    AutopsyCategoryOption(value: 'inspection', label: 'Inspection', order: 5),
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