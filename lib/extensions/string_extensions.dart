import 'package:flutter/material.dart';
import '../utils/status_utils.dart';
import '../widgets/status_label.dart';

extension StatusString on String {
  Widget asStatusWidget() {
    return StatusLabel(status: this);
  }
  
  Widget asStatusChip() {
    return StatusUtils.buildStatusWidget(this);
  }
  
  String get transformedStatus {
    return StatusUtils.getDisplayText(this);
  }
}