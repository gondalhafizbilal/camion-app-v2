import 'package:camion/core/config/app_flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._({
    required this.flavor,
    required this.envFile,
    required this.baseUrl,
    required this.chatbotBaseUrl,
    required this.assetsHost,
    required this.staticScreensMode,
    required this.enableNetworkLogs,
  });

  static late final AppConfig instance;

  final AppFlavor flavor;
  final String envFile;
  final String baseUrl;
  final String chatbotBaseUrl;
  final String assetsHost;
  final bool staticScreensMode;
  final bool enableNetworkLogs;

  String get runtimeEnvironmentMarker =>
      '${flavor.name}:${normalizeUrl(baseUrl)}';

  static void initialize({required AppFlavor flavor, required String envFile}) {
    final defaultBaseUrl = flavor.isProduction
        ? 'https://api.camion-app.com'
        : 'https://api.dev.camiontrading.com';
    final defaultChatbotBaseUrl = flavor.isProduction
        ? 'https://chatbot.camion-app.com'
        : 'https://chatbot.dev.camiontrading.com';
    final resolvedBaseUrl = _stringFromDefine(
      key: 'BASE_URL',
      fallback: defaultBaseUrl,
    );
    instance = AppConfig._(
      flavor: flavor,
      envFile: envFile,
      baseUrl: resolvedBaseUrl,
      chatbotBaseUrl: _stringFromDefine(
        key: 'CHATBOT_BASE_URL',
        fallback: defaultChatbotBaseUrl,
      ),
      assetsHost: _stringFromDefine(
        key: 'ASSETS_HOST',
        fallback: _deriveAssetsHostFromBaseUrl(resolvedBaseUrl),
      ),
      // Safety lock: production builds must never run static screens mode,
      // even if a bad env or dart-define accidentally enables it.
      staticScreensMode: flavor.isProduction
          ? false
          : _boolFromDefine(key: 'STATIC_SCREENS_MODE', fallback: false),
      enableNetworkLogs: _boolFromDefine(
        key: 'ENABLE_NETWORK_LOGS',
        fallback: kDebugMode,
      ),
    );
  }

  static String normalizeUrl(String value) {
    final trimmed = value.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.host.trim().isEmpty) {
      return trimmed.toLowerCase();
    }
    final scheme = parsed.scheme.isEmpty
        ? 'https'
        : parsed.scheme.toLowerCase();
    final host = parsed.host.toLowerCase();
    final port = parsed.hasPort ? ':${parsed.port}' : '';
    final path = parsed.path.endsWith('/') && parsed.path.length > 1
        ? parsed.path.substring(0, parsed.path.length - 1)
        : parsed.path;
    return '$scheme://$host$port$path';
  }

  static String _stringFromDefine({
    required String key,
    required String fallback,
  }) {
    final defined = _stringByKey(key);
    return defined.isEmpty ? fallback : defined;
  }

  static String _stringByKey(String key) {
    final fromDefine = switch (key) {
      'BASE_URL' => const String.fromEnvironment('BASE_URL'),
      'ENABLE_NETWORK_LOGS' => const String.fromEnvironment(
        'ENABLE_NETWORK_LOGS',
      ),
      'STATIC_SCREENS_MODE' => const String.fromEnvironment(
        'STATIC_SCREENS_MODE',
      ),
      'ASSETS_HOST' => const String.fromEnvironment('ASSETS_HOST'),
      'CHATBOT_BASE_URL' => const String.fromEnvironment('CHATBOT_BASE_URL'),
      _ => '',
    };
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return dotenv.env[key] ?? '';
  }

  static String _deriveAssetsHostFromBaseUrl(String baseUrl) {
    final parsed = Uri.tryParse(baseUrl.trim());
    if (parsed == null || parsed.host.trim().isEmpty) {
      return '';
    }
    final host = parsed.host.trim();
    final replacedHost = host.startsWith('api.')
        ? 'assets.${host.substring(4)}'
        : host;
    return '${parsed.scheme.isEmpty ? 'https' : parsed.scheme}://$replacedHost';
  }

  static bool _boolFromDefine({required String key, required bool fallback}) {
    final value = _stringByKey(key);
    if (value.isEmpty) {
      return fallback;
    }
    return value.toLowerCase() == 'true';
  }
}
