import 'package:json_annotation/json_annotation.dart';

class BoolFromIntConverter implements JsonConverter<bool?, dynamic> {
  const BoolFromIntConverter();

  @override
  bool? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is bool) return json;
    if (json is int) return json == 1;
    if (json is String) return json == '1' || json.toLowerCase() == 'true';
    return null;
  }

  @override
  dynamic toJson(bool? value) => value;
}
