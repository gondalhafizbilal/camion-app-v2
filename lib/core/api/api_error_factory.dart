import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/api/local_status_codes.dart';
import 'package:flutter/material.dart';

class ApiErrorFactory {
  static const String noDataAvailableMessage =
      'Backend is not responding. Please try again later.';
  static const String maintenanceMessage =
      "We're working on it. Please wait a moment and try again.";

  static ApiErrorModel get defaultError => ApiErrorModel(
    message: maintenanceMessage,
    icon: Icons.error,
    statusCode: LocalStatusCodes.defaultError,
  );

  static ApiErrorModel serviceUnavailable({int? statusCode}) => ApiErrorModel(
    message: noDataAvailableMessage,
    icon: Icons.error_outline,
    statusCode: statusCode ?? LocalStatusCodes.defaultError,
  );
}
