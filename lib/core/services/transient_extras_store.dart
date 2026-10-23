class TransientExtrasStore {
  final Map<String, dynamic> _store = {};
  int _counter = 0;

  // Save any payload and return a short-lived key
  String put(dynamic value) {
    final key = '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
    _store[key] = value;
    return key;
  }

  // Retrieve and remove the payload by key
  T? take<T>(String key) {
    final value = _store.remove(key);
    if (value is T) return value;
    try {
      return value as T?;
    } catch (_) {
      return null;
    }
  }
}
