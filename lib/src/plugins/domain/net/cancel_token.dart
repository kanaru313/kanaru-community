/// A request to stop a running fetch. Cancelling twice is harmless.
class CancelToken {
  final _listeners = <void Function()>{};
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  /// How many listeners are registered; a fetch removes its own when it ends.
  int get listenerCount => _listeners.length;

  /// Calls [listener] once when [cancel] is called and returns a function that
  /// removes it. A token shared by many fetches must not keep the ones that
  /// have ended, so every caller removes its listener when done.
  void Function() listen(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final pending = _listeners.toList();
    _listeners.clear();
    for (final listener in pending) {
      listener();
    }
  }
}
