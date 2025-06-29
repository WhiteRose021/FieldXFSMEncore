// lib/models/autopsy_responses.dart

class AutopsyListResponse {
  final List<CAutopsy> data;
  final int total;
  final bool permissionDenied;

  const AutopsyListResponse({
    required this.data,
    required this.total,
    required this.permissionDenied,
  });
}

class AutopsyDetailResponse {
  final CAutopsy? data;
  final bool permissionDenied;

  const AutopsyDetailResponse({
    required this.data,
    required this.permissionDenied,
  });
}