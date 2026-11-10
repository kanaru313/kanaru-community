import 'dart:async';

typedef TimerFactory = Timer Function(Duration after, void Function() run);

/// Collects the cover keys that `coverMissesProvider` reports and says when
/// they are due: [debounce] after the last one. The controller takes them as
/// one job.
class CoverMissQueue {
  CoverMissQueue({
    required Stream<String>? misses,
    required this.accepting,
    required this.timer,
    required this.debounce,
    required this.onDue,
  }) {
    _sub = misses?.listen(_add);
  }

  /// False while setup is not done (or the controller is gone): misses are
  /// dropped.
  final bool Function() accepting;
  final TimerFactory timer;
  final Duration debounce;
  final void Function() onDue;

  StreamSubscription<String>? _sub;
  Timer? _timer;
  final Set<String> _keys = {};
  bool _due = false;

  /// Keys are waiting and the debounce has passed.
  bool get ready => _due && _keys.isNotEmpty;

  /// Takes the waiting keys and clears the queue.
  Set<String> take() {
    final keys = {..._keys};
    _keys.clear();
    _due = false;
    return keys;
  }

  void _add(String key) {
    try {
      if (!accepting()) return;
    } on Object {
      return;
    }
    _keys.add(key);
    _timer?.cancel();
    _timer = timer(debounce, () {
      _timer = null;
      _due = true;
      onDue();
    });
  }

  void dispose() {
    _timer?.cancel();
    unawaited(_sub?.cancel());
  }
}
