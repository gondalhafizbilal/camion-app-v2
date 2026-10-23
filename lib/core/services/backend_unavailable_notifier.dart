import 'package:flutter/foundation.dart';

class BackendUnavailableNotifier {
  BackendUnavailableNotifier._();

  static final ValueNotifier<bool> isBackendUnavailable = ValueNotifier<bool>(
    false,
  );

  static void show() {
    if (!isBackendUnavailable.value) {
      isBackendUnavailable.value = true;
    }
  }

  static void hide() {
    if (isBackendUnavailable.value) {
      isBackendUnavailable.value = false;
    }
  }
}
