import 'dart:async';

class StartupGateService {
  StartupGateService() : _releaseCompleter = Completer<void>();

  final Completer<void> _releaseCompleter;
  bool _isReleased = false;

  bool get isReleased => _isReleased;

  Future<void> waitForRelease() => _isReleased
      ? Future.value()
      : _releaseCompleter.future;

  void release() {
    if (_isReleased) return;
    _isReleased = true;
    if (!_releaseCompleter.isCompleted) {
      _releaseCompleter.complete();
    }
  }
}
