import 'dart:async';

/// The per-plugin pause that follows a rate-limited run. In memory only (a
/// restart starts without pauses); set by the runner and by nothing else.
///
/// A pause is checked once, when a run starts; runs in flight finish.
class PluginPauses {
  PluginPauses({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final _entries = <String, ({DateTime until, Timer timer})>{};
  final _listeners = <String, Set<void Function()>>{};
  bool _disposed = false;

  /// When the pause of [installId] ends, or null when it is not paused.
  DateTime? until(String installId) {
    final entry = _entries[installId];
    if (entry == null || !_now().isBefore(entry.until)) return null;
    return entry.until;
  }

  /// Pauses [installId] for [duration] from now (a longer running pause is
  /// kept, a shorter one never shortens it).
  void pause(String installId, Duration duration) {
    if (_disposed) return;
    final until = _now().add(duration);
    final old = _entries[installId];
    if (old != null && old.until.isAfter(until)) return;
    old?.timer.cancel();
    _entries[installId] = (
      until: until,
      timer: Timer(duration, () => _end(installId)),
    );
    _notify(installId);
  }

  /// Calls [listener] whenever the pause of [installId] starts or ends;
  /// returns the function that stops it.
  void Function() listen(String installId, void Function() listener) {
    final set = _listeners.putIfAbsent(installId, () => {});
    set.add(listener);
    return () {
      set.remove(listener);
      if (set.isEmpty) _listeners.remove(installId);
    };
  }

  /// Cancels every timer; the pauses are forgotten.
  void dispose() {
    _disposed = true;
    for (final entry in _entries.values) {
      entry.timer.cancel();
    }
    _entries.clear();
    _listeners.clear();
  }

  void _end(String installId) {
    if (_entries.remove(installId) != null) _notify(installId);
  }

  void _notify(String installId) {
    for (final listener in [...?_listeners[installId]]) {
      listener();
    }
  }
}
