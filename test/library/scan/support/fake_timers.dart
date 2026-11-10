import 'dart:async';

/// A clock and timers the test moves by hand.
class FakeTimers {
  DateTime now = DateTime(2026, 11, 10);
  final List<_FakeTimer> _timers = [];
  int created = 0;

  int get active => _timers.where((t) => t.isActive).length;

  Timer create(Duration after, void Function() run) {
    created++;
    final t = _FakeTimer(now.add(after), run);
    _timers.add(t);
    return t;
  }

  /// Moves time forward, firing due timers in order.
  Future<void> advance(Duration by) async {
    final end = now.add(by);
    while (true) {
      final due =
          _timers.where((t) => t.isActive && !t.at.isAfter(end)).toList()
            ..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      now = due.first.at;
      due.first.fire();
      await _settle();
    }
    now = end;
    await _settle();
  }

  /// Lets queued microtasks and zero-delay futures run.
  Future<void> settle() => _settle();

  Future<void> _settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.at, this._run);

  final DateTime at;
  final void Function() _run;
  bool _done = false;

  void fire() {
    _done = true;
    _run();
  }

  @override
  void cancel() => _done = true;

  @override
  bool get isActive => !_done;

  @override
  int get tick => _done ? 1 : 0;
}
