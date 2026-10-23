import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TikTokBusinessService {
  static const MethodChannel _channel = MethodChannel('tiktok_business_sdk');
  static bool get _isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!_isSupportedPlatform) return;
    await _invoke('initialize', logLabel: 'initialize');
  }

  static Future<int?> requestTrackingAuthorization() async {
    if (!_isSupportedPlatform) return null;
    final status = await _invoke<int>(
      'requestTrackingAuthorization',
      logLabel: 'requestTrackingAuthorization',
    );
    return status;
  }

  static Future<void> identify({
    String? externalId,
    String? externalUserName,
    String? phoneNumber,
    String? email,
  }) async {
    if (!_isSupportedPlatform) return;
    final payload = {
      'externalId': externalId,
      'externalUserName': externalUserName,
      'phoneNumber': phoneNumber,
      'email': email,
    };
    await _invoke('identify', arguments: payload, logLabel: 'identify');
  }

  static Future<void> trackBaseEvent(
    String eventName, {
    String? eventId,
  }) async {
    if (!_isSupportedPlatform) return;
    final payload = {
      'eventName': eventName,
      'eventId': eventId,
    };
    await _invoke('trackBaseEvent', arguments: payload, logLabel: 'trackBaseEvent');
  }

  static Future<void> trackContentsEvent(
    String eventType, {
    String? eventId,
    String? contentId,
    String? description,
    String? contentType,
    String? value,
    String? currency,
    List<Map<String, dynamic>>? contents,
  }) async {
    if (!_isSupportedPlatform) return;
    final payload = {
      'eventType': eventType,
      'eventId': eventId,
      'properties': {
        'contentId': contentId,
        'description': description,
        'contentType': contentType,
        'value': value,
        'currency': currency,
        'contents': contents,
      },
    };
    await _invoke(
      'trackContentsEvent',
      arguments: payload,
      logLabel: 'trackContentsEvent',
    );
  }

  static Future<void> addPaymentInfo({String? eventId}) {
    return trackBaseEvent('add_payment_info', eventId: eventId);
  }

  static Future<void> generateLead({String? eventId}) {
    return trackBaseEvent('generate_lead', eventId: eventId);
  }

  static Future<void> launchApp({String? eventId}) {
    return trackBaseEvent('launch_app', eventId: eventId);
  }

  static Future<void> login({String? eventId}) {
    return trackBaseEvent('login', eventId: eventId);
  }

  static Future<void> rate({String? eventId}) {
    return trackBaseEvent('rate', eventId: eventId);
  }

  static Future<void> viewContent({
    String? eventId,
    String? contentId,
    String? description,
    String? contentType,
    String? value,
    String? currency = 'USD',
    List<Map<String, dynamic>>? contents,
  }) {
    return trackContentsEvent(
      'view_content',
      eventId: eventId,
      contentId: contentId,
      description: description,
      contentType: contentType,
      value: value,
      currency: currency,
      contents: contents,
    );
  }

  static Future<void> addToCart({
    String? eventId,
    String? contentId,
    String? description,
    String? contentType,
    String? value,
    String? currency = 'USD',
    List<Map<String, dynamic>>? contents,
  }) {
    return trackContentsEvent(
      'add_to_cart',
      eventId: eventId,
      contentId: contentId,
      description: description,
      contentType: contentType,
      value: value,
      currency: currency,
      contents: contents,
    );
  }

  static Future<void> addToWishlist({
    String? eventId,
    String? contentId,
    String? description,
    String? contentType,
    String? value,
    String? currency = 'USD',
    List<Map<String, dynamic>>? contents,
  }) {
    return trackContentsEvent(
      'add_to_wishlist',
      eventId: eventId,
      contentId: contentId,
      description: description,
      contentType: contentType,
      value: value,
      currency: currency,
      contents: contents,
    );
  }

  static Future<void> checkout({
    String? eventId,
    String? contentId,
    String? description,
    String? contentType,
    String? value,
    String? currency = 'USD',
    List<Map<String, dynamic>>? contents,
  }) {
    return trackContentsEvent(
      'checkout',
      eventId: eventId,
      contentId: contentId,
      description: description,
      contentType: contentType,
      value: value,
      currency: currency,
      contents: contents,
    );
  }

  static Future<void> purchase({
    String? eventId,
    String? contentId,
    String? description,
    String? contentType,
    String? value,
    String? currency = 'USD',
    List<Map<String, dynamic>>? contents,
  }) {
    return trackContentsEvent(
      'purchase',
      eventId: eventId,
      contentId: contentId,
      description: description,
      contentType: contentType,
      value: value,
      currency: currency,
      contents: contents,
    );
  }

  static Future<T?> _invoke<T>(
    String method, {
    Map<String, dynamic>? arguments,
    required String logLabel,
  }) async {
    try {
      debugPrint(
        '[TIKTOK][DART] $logLabel ${arguments == null ? "" : jsonEncode(arguments)}'
            .trim(),
      );
      final result = await _channel.invokeMethod<T>(method, arguments);
      debugPrint('[TIKTOK][DART] $logLabel completed');
      return result;
    } catch (error, stackTrace) {
      debugPrint('[TIKTOK][DART] $logLabel failed: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
}
