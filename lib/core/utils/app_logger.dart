import 'dart:async';
import 'dart:developer' as developer;

import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:flutter/foundation.dart';

bool get _logsEnabled {
  try {
    return AppConfig.instance.enableNetworkLogs ||
        (AppConfig.instance.flavor != AppFlavor.production && kDebugMode);
  } catch (_) {
    return kDebugMode;
  }
}

void appLog(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!_logsEnabled) return;
  developer.log(
    message,
    time: time,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
  );
}

void appDebugPrint(String? message, {int? wrapWidth}) {
  if (!_logsEnabled) return;
  debugPrint(message, wrapWidth: wrapWidth);
}

void appPrint(Object? object) {
  if (!_logsEnabled) return;
  debugPrint(object?.toString());
}
