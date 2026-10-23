enum AppFlavor { development, production }

extension AppFlavorX on AppFlavor {
  String get name {
    switch (this) {
      case AppFlavor.development:
        return 'development';
      case AppFlavor.production:
        return 'production';
    }
  }

  bool get isDevelopment => this == AppFlavor.development;
  bool get isProduction => this == AppFlavor.production;
}
