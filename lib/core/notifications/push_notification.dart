import 'dart:io';
import 'package:camion/core/notifications/local_notifications.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationsService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static String? token;

  static bool get _isMobileSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future init() async {
    try {
      if (!_isMobileSupportedPlatform) {
        appLog('[FCM] init skipped: unsupported platform.');
        return;
      }
      final results = await Future.wait<dynamic>([
        messaging.requestPermission(),
        AwesomeNotificationService.init(),
      ]);
      final permission = results.first;
      if (permission is NotificationSettings) {
        appLog(
          '[FCM] Permission status: ${permission.authorizationStatus.name} '
          '(alert=${permission.alert.name}, badge=${permission.badge.name}, sound=${permission.sound.name})',
        );
      }

      appLog('[FCM] Firebase apps initialized: ${Firebase.apps.length}');
      token = await messaging.getToken();
      if (token != null && token!.trim().isNotEmpty) {
        appLog(
          '[FCM] Token acquired (${token!.length} chars): ${_maskToken(token!)}',
        );
      } else {
        appLog('[FCM] Failed to get FCM token (null/empty).');
      }
    } catch (e, st) {
      appLog('[FCM] init failed: $e', stackTrace: st);
    }
  }

  static Future<String?> resolveAuthFlowToken() async {
    if (!_isMobileSupportedPlatform) {
      appLog('[FCM] auth token skipped: unsupported platform.');
      return null;
    }

    final cached = token?.trim() ?? '';

    try {
      if (Platform.isIOS) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final apnsToken = await messaging.getAPNSToken();
        appLog(
          '[FCM] iOS APNs token present: ${apnsToken?.isNotEmpty == true}',
        );
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        appLog('[FCM] Android token fetch path selected.');
      }
      final liveToken = (await messaging.getToken())?.trim() ?? '';
      if (liveToken.isNotEmpty) {
        token = liveToken;
        appLog(
          '[FCM] auth token selected (live, ${Platform.isIOS ? 'iOS' : 'Android'}): ${maskTokenForLogs(liveToken)}',
        );
        return liveToken;
      }
      if (cached.isNotEmpty) {
        appLog(
          '[FCM] auth token selected (cached fallback, ${Platform.isIOS ? 'iOS' : 'Android'}): ${maskTokenForLogs(cached)}',
        );
      }
      return cached.isNotEmpty ? cached : null;
    } catch (e, st) {
      appLog('[FCM] auth token resolve failed: $e', stackTrace: st);
      return cached.isNotEmpty ? cached : null;
    }
  }

  static Future handleNotifications() async {
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    handleForegroundMessage();

    messaging.subscribeToTopic('all').then((_) {
      appLog('Subscribed to topic');
    });
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
    appLog('BG Message: ${message.notification?.title ?? 'null'}');
    await AwesomeNotificationService.showBasicNotification(message);
  }

  static void handleForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AwesomeNotificationService.showBasicNotification(message);
    });
  }

  static String _maskToken(String value) {
    if (value.length <= 12) return value;
    final start = value.substring(0, 6);
    final end = value.substring(value.length - 6);
    return '$start...$end';
  }

  static String maskTokenForLogs(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '<empty>';
    return _maskToken(normalized);
  }
}
