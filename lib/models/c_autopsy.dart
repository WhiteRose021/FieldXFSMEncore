// lib/models/c_autopsy.dart - Ultra-safe version with no direct casts

import 'package:fieldx_fsm/models/autopsy_exceptions123.dart';

class CAutopsy {
  final String id;
  final String? name;
  final String? description;
  final String? createdAt;
  final String? modifiedAt;
  final String? assignedUserId;
  final bool? deleted;
  
  // Autopsy-specific fields
  final String? autopsyFullAddress;
  final String? autopsyStreet;
  final String? autopsyPostalCode;
  final String? autopsyMunicipality;
  final String? autopsyState;
  final String? autopsyCity;
  final String? autopsyCustomerName;
  final String? autopsyCustomerEmail;
  final String? autopsyCustomerMobile;
  final String? autopsyLandlinePhoneNumber;
  final String? autopsyStatus;
  final String? autopsyCategory;
  final String? autopsyComments;
  final String? technicalCheckStatus;
  final String? soilWorkStatus;
  final String? constructionStatus;
  final String? splicingStatus;
  final String? billingStatus;
  final String? malfunctionStatus;
  final String? autopsyLatitude;
  final String? autopsyLongitude;
  final String? autopsyOrderNumber;
  final String? autopsyBid;
  final String? autopsyCab;
  final String? autopsyAge;
  final String? autopsyAk;
  final String? autopsyAdminEmail;
  final String? autopsyAdminMobile;
  final String? autopsyAdminLandline;
  final bool? autopsyOutOfSystem;
  final String? autopsyCustomerFloor;
  final String? autopsyPilot;
  final String? autopsyTtlp;
  final String? autopsyTtlLpppTest;
  final String? buildingId;
  final String? type;
  final String? adminAutopsyName;

  const CAutopsy({
    required this.id,
    this.name,
    this.description,
    this.createdAt,
    this.modifiedAt,
    this.assignedUserId,
    this.deleted,
    this.autopsyFullAddress,
    this.autopsyStreet,
    this.autopsyPostalCode,
    this.autopsyMunicipality,
    this.autopsyState,
    this.autopsyCity,
    this.autopsyCustomerName,
    this.autopsyCustomerEmail,
    this.autopsyCustomerMobile,
    this.autopsyLandlinePhoneNumber,
    this.autopsyStatus,
    this.autopsyCategory,
    this.autopsyComments,
    this.technicalCheckStatus,
    this.soilWorkStatus,
    this.constructionStatus,
    this.splicingStatus,
    this.billingStatus,
    this.malfunctionStatus,
    this.autopsyLatitude,
    this.autopsyLongitude,
    this.autopsyOrderNumber,
    this.autopsyBid,
    this.autopsyCab,
    this.autopsyAge,
    this.autopsyAk,
    this.autopsyAdminEmail,
    this.autopsyAdminMobile,
    this.autopsyAdminLandline,
    this.autopsyOutOfSystem,
    this.autopsyCustomerFloor,
    this.autopsyPilot,
    this.autopsyTtlp,
    this.autopsyTtlLpppTest,
    this.buildingId,
    this.type,
    this.adminAutopsyName,
  });

  /// Ultra-safe factory constructor that avoids ALL direct casts
  factory CAutopsy.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: Print the first few fields to see what we're getting
      print('🔍 DEBUG: CAutopsy.fromJson received:');
      json.forEach((key, value) {
        print('  $key: ${value?.runtimeType} = $value');
      });
      
      return CAutopsy(
        // Required field with fallback
        id: _extractString(json, 'id') ?? _extractString(json, 'ID') ?? '',
        
        // Basic fields
        name: _extractString(json, 'name'),
        description: _extractString(json, 'description'),
        createdAt: _extractString(json, 'created_at') ?? _extractString(json, 'createdAt'),
        modifiedAt: _extractString(json, 'modified_at') ?? _extractString(json, 'modifiedAt'),
        assignedUserId: _extractString(json, 'assigned_user_id') ?? _extractString(json, 'assignedUserId'),
        deleted: _extractBool(json, 'deleted'),
        
        // Autopsy fields - handle various possible field names
        autopsyFullAddress: _extractString(json, 'autopsyfulladdress') ?? _extractString(json, 'autopsyFullAddress'),
        autopsyStreet: _extractString(json, 'autopsystreet') ?? _extractString(json, 'autopsyStreet'),
        autopsyPostalCode: _extractString(json, 'autopsypostalcode') ?? _extractString(json, 'autopsyPostalCode'),
        autopsyMunicipality: _extractString(json, 'autopsymunicipality') ?? _extractString(json, 'autopsyMunicipality'),
        autopsyState: _extractString(json, 'autopsystate') ?? _extractString(json, 'autopsyState'),
        autopsyCity: _extractString(json, 'autopsycity') ?? _extractString(json, 'autopsyCity'),
        autopsyCustomerName: _extractString(json, 'autopsycustomername') ?? _extractString(json, 'autopsyCustomerName'),
        autopsyCustomerEmail: _extractString(json, 'autopsycustomeremail') ?? _extractString(json, 'autopsyCustomerEmail'),
        autopsyCustomerMobile: _extractString(json, 'autopsycustomermobile') ?? _extractString(json, 'autopsyCustomerMobile'),
        autopsyLandlinePhoneNumber: _extractString(json, 'autopsylandlinephonenumber') ?? _extractString(json, 'autopsyLandlinePhoneNumber'),
        autopsyStatus: _extractString(json, 'autopsystatus') ?? _extractString(json, 'autopsyStatus'),
        autopsyCategory: _extractString(json, 'autopsycategory') ?? _extractString(json, 'autopsyCategory'),
        autopsyComments: _extractString(json, 'autopsycomments') ?? _extractString(json, 'autopsyComments'),
        technicalCheckStatus: _extractString(json, 'technicalcheckstatus') ?? _extractString(json, 'technicalCheckStatus'),
        soilWorkStatus: _extractString(json, 'soilworkstatus') ?? _extractString(json, 'soilWorkStatus'),
        constructionStatus: _extractString(json, 'constructionstatus') ?? _extractString(json, 'constructionStatus'),
        splicingStatus: _extractString(json, 'splicingstatus') ?? _extractString(json, 'splicingStatus'),
        billingStatus: _extractString(json, 'billingstatus') ?? _extractString(json, 'billingStatus'),
        malfunctionStatus: _extractString(json, 'malfunctionstatus') ?? _extractString(json, 'malfunctionStatus'),
        autopsyLatitude: _extractString(json, 'autopsylatitude') ?? _extractString(json, 'autopsyLatitude'),
        autopsyLongitude: _extractString(json, 'autopsylongtitude') ?? _extractString(json, 'autopsyLongitude'),
        autopsyOrderNumber: _extractString(json, 'autopsyordernumber') ?? _extractString(json, 'autopsyOrderNumber'),
        autopsyBid: _extractString(json, 'autopsybid') ?? _extractString(json, 'autopsyBid'),
        autopsyCab: _extractString(json, 'autopsycab') ?? _extractString(json, 'autopsyCab'),
        autopsyAge: _extractString(json, 'autopsyage') ?? _extractString(json, 'autopsyAge'),
        autopsyAk: _extractString(json, 'autopsyak') ?? _extractString(json, 'autopsyAk'),
        autopsyAdminEmail: _extractString(json, 'autopsyadminemail') ?? _extractString(json, 'autopsyAdminEmail'),
        autopsyAdminMobile: _extractString(json, 'autopsyadminmobile') ?? _extractString(json, 'autopsyAdminMobile'),
        autopsyAdminLandline: _extractString(json, 'autopsyadminlandline') ?? _extractString(json, 'autopsyAdminLandline'),
        autopsyOutOfSystem: _extractBool(json, 'autopsyoutofsystem') ?? _extractBool(json, 'autopsyOutOfSystem'),
        autopsyCustomerFloor: _extractString(json, 'autopsycustomerfloor') ?? _extractString(json, 'autopsyCustomerFloor'),
        autopsyPilot: _extractString(json, 'autopsypilot') ?? _extractString(json, 'autopsyPilot'),
        autopsyTtlp: _extractString(json, 'autopsyttlp') ?? _extractString(json, 'autopsyTtlp'),
        autopsyTtlLpppTest: _extractString(json, 'autopsyttllppptest') ?? _extractString(json, 'autopsyTtlLpppTest'),
        buildingId: _extractString(json, 'building_id') ?? _extractString(json, 'buildingId'),
        type: _extractString(json, 'type'),
        adminAutopsyName: _extractString(json, 'adminautopsyname') ?? _extractString(json, 'adminAutopsyName'),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to parse CAutopsy from JSON: $e');
      print('📋 JSON keys: ${json.keys.toList()}');
      print('📋 JSON values sample:');
      json.entries.take(5).forEach((entry) {
        print('  ${entry.key}: ${entry.value?.runtimeType} = ${entry.value}');
      });
      
      throw AutopsyDataException(
        message: 'Failed to parse CAutopsy from JSON: $e',
        originalError: e,
        details: {
          'jsonKeys': json.keys.toList(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  /// Safely extract string value with no casting
  static String? _extractString(Map<String, dynamic> json, String key) {
    try {
      final value = json[key];
      if (value == null) return null;
      
      if (value is String) {
        return value.isEmpty ? null : value;
      } else if (value is bool) {
        return value.toString();
      } else if (value is num) {
        return value.toString();
      } else {
        return value.toString();
      }
    } catch (e) {
      print('⚠️ WARNING: Failed to extract string for key "$key": $e');
      return null;
    }
  }

  /// Safely extract boolean value with no casting
  static bool? _extractBool(Map<String, dynamic> json, String key) {
    try {
      final value = json[key];
      if (value == null) return null;
      
      if (value is bool) {
        return value;
      } else if (value is int) {
        return value == 1;
      } else if (value is String) {
        final lower = value.toLowerCase().trim();
        if (lower.isEmpty) return null;
        return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on';
      } else {
        return false;
      }
    } catch (e) {
      print('⚠️ WARNING: Failed to extract bool for key "$key": $e');
      return null;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (deleted != null) 'deleted': deleted,
      
      // Autopsy fields
      if (autopsyFullAddress != null) 'autopsyfulladdress': autopsyFullAddress,
      if (autopsyStreet != null) 'autopsystreet': autopsyStreet,
      if (autopsyPostalCode != null) 'autopsypostalcode': autopsyPostalCode,
      if (autopsyMunicipality != null) 'autopsymunicipality': autopsyMunicipality,
      if (autopsyState != null) 'autopsystate': autopsyState,
      if (autopsyCity != null) 'autopsycity': autopsyCity,
      if (autopsyCustomerName != null) 'autopsycustomername': autopsyCustomerName,
      if (autopsyCustomerEmail != null) 'autopsycustomeremail': autopsyCustomerEmail,
      if (autopsyCustomerMobile != null) 'autopsycustomermobile': autopsyCustomerMobile,
      if (autopsyLandlinePhoneNumber != null) 'autopsylandlinephonenumber': autopsyLandlinePhoneNumber,
      if (autopsyStatus != null) 'autopsystatus': autopsyStatus,
      if (autopsyCategory != null) 'autopsycategory': autopsyCategory,
      if (autopsyComments != null) 'autopsycomments': autopsyComments,
      if (technicalCheckStatus != null) 'technicalcheckstatus': technicalCheckStatus,
      if (soilWorkStatus != null) 'soilworkstatus': soilWorkStatus,
      if (constructionStatus != null) 'constructionstatus': constructionStatus,
      if (splicingStatus != null) 'splicingstatus': splicingStatus,
      if (billingStatus != null) 'billingstatus': billingStatus,
      if (malfunctionStatus != null) 'malfunctionstatus': malfunctionStatus,
      if (autopsyLatitude != null) 'autopsylatitude': autopsyLatitude,
      if (autopsyLongitude != null) 'autopsylongtitude': autopsyLongitude,
      if (autopsyOrderNumber != null) 'autopsyordernumber': autopsyOrderNumber,
      if (autopsyBid != null) 'autopsybid': autopsyBid,
      if (autopsyCab != null) 'autopsycab': autopsyCab,
      if (autopsyAge != null) 'autopsyage': autopsyAge,
      if (autopsyAk != null) 'autopsyak': autopsyAk,
      if (autopsyAdminEmail != null) 'autopsyadminemail': autopsyAdminEmail,
      if (autopsyAdminMobile != null) 'autopsyadminmobile': autopsyAdminMobile,
      if (autopsyAdminLandline != null) 'autopsyadminlandline': autopsyAdminLandline,
      if (autopsyOutOfSystem != null) 'autopsyoutofsystem': autopsyOutOfSystem,
      if (autopsyCustomerFloor != null) 'autopsycustomerfloor': autopsyCustomerFloor,
      if (autopsyPilot != null) 'autopsypilot': autopsyPilot,
      if (autopsyTtlp != null) 'autopsyttlp': autopsyTtlp,
      if (autopsyTtlLpppTest != null) 'autopsyttllppptest': autopsyTtlLpppTest,
      if (buildingId != null) 'building_id': buildingId,
      if (type != null) 'type': type,
      if (adminAutopsyName != null) 'adminautopsyname': adminAutopsyName,
    };
  }

  /// Copy with method
  CAutopsy copyWith({
    String? id,
    String? name,
    String? description,
    String? createdAt,
    String? modifiedAt,
    String? assignedUserId,
    bool? deleted,
    String? autopsyFullAddress,
    String? autopsyStreet,
    String? autopsyPostalCode,
    String? autopsyMunicipality,
    String? autopsyState,
    String? autopsyCity,
    String? autopsyCustomerName,
    String? autopsyCustomerEmail,
    String? autopsyCustomerMobile,
    String? autopsyLandlinePhoneNumber,
    String? autopsyStatus,
    String? autopsyCategory,
    String? autopsyComments,
    String? technicalCheckStatus,
    String? soilWorkStatus,
    String? constructionStatus,
    String? splicingStatus,
    String? billingStatus,
    String? malfunctionStatus,
    String? autopsyLatitude,
    String? autopsyLongitude,
    String? autopsyOrderNumber,
    String? autopsyBid,
    String? autopsyCab,
    String? autopsyAge,
    String? autopsyAk,
    String? autopsyAdminEmail,
    String? autopsyAdminMobile,
    String? autopsyAdminLandline,
    bool? autopsyOutOfSystem,
    String? autopsyCustomerFloor,
    String? autopsyPilot,
    String? autopsyTtlp,
    String? autopsyTtlLpppTest,
    String? buildingId,
    String? type,
    String? adminAutopsyName,
  }) {
    return CAutopsy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      deleted: deleted ?? this.deleted,
      autopsyFullAddress: autopsyFullAddress ?? this.autopsyFullAddress,
      autopsyStreet: autopsyStreet ?? this.autopsyStreet,
      autopsyPostalCode: autopsyPostalCode ?? this.autopsyPostalCode,
      autopsyMunicipality: autopsyMunicipality ?? this.autopsyMunicipality,
      autopsyState: autopsyState ?? this.autopsyState,
      autopsyCity: autopsyCity ?? this.autopsyCity,
      autopsyCustomerName: autopsyCustomerName ?? this.autopsyCustomerName,
      autopsyCustomerEmail: autopsyCustomerEmail ?? this.autopsyCustomerEmail,
      autopsyCustomerMobile: autopsyCustomerMobile ?? this.autopsyCustomerMobile,
      autopsyLandlinePhoneNumber: autopsyLandlinePhoneNumber ?? this.autopsyLandlinePhoneNumber,
      autopsyStatus: autopsyStatus ?? this.autopsyStatus,
      autopsyCategory: autopsyCategory ?? this.autopsyCategory,
      autopsyComments: autopsyComments ?? this.autopsyComments,
      technicalCheckStatus: technicalCheckStatus ?? this.technicalCheckStatus,
      soilWorkStatus: soilWorkStatus ?? this.soilWorkStatus,
      constructionStatus: constructionStatus ?? this.constructionStatus,
      splicingStatus: splicingStatus ?? this.splicingStatus,
      billingStatus: billingStatus ?? this.billingStatus,
      malfunctionStatus: malfunctionStatus ?? this.malfunctionStatus,
      autopsyLatitude: autopsyLatitude ?? this.autopsyLatitude,
      autopsyLongitude: autopsyLongitude ?? this.autopsyLongitude,
      autopsyOrderNumber: autopsyOrderNumber ?? this.autopsyOrderNumber,
      autopsyBid: autopsyBid ?? this.autopsyBid,
      autopsyCab: autopsyCab ?? this.autopsyCab,
      autopsyAge: autopsyAge ?? this.autopsyAge,
      autopsyAk: autopsyAk ?? this.autopsyAk,
      autopsyAdminEmail: autopsyAdminEmail ?? this.autopsyAdminEmail,
      autopsyAdminMobile: autopsyAdminMobile ?? this.autopsyAdminMobile,
      autopsyAdminLandline: autopsyAdminLandline ?? this.autopsyAdminLandline,
      autopsyOutOfSystem: autopsyOutOfSystem ?? this.autopsyOutOfSystem,
      autopsyCustomerFloor: autopsyCustomerFloor ?? this.autopsyCustomerFloor,
      autopsyPilot: autopsyPilot ?? this.autopsyPilot,
      autopsyTtlp: autopsyTtlp ?? this.autopsyTtlp,
      autopsyTtlLpppTest: autopsyTtlLpppTest ?? this.autopsyTtlLpppTest,
      buildingId: buildingId ?? this.buildingId,
      type: type ?? this.type,
      adminAutopsyName: adminAutopsyName ?? this.adminAutopsyName,
    );
  }

  @override
  String toString() {
    return 'CAutopsy(id: $id, name: $name, status: $autopsyStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CAutopsy && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}