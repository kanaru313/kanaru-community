import 'dart:async';

/// Holds back the text of a list filter field until typing pauses, so each
/// keystroke does not start a whole-list query. The field itself stays
/// immediate; only the text handed to the query waits.
class FilterDebouncer {
  FilterDebouncer({this.delay = const Duration(milliseconds: 250)});

  /// Quiet time after the last keystroke before [apply] runs.
  final Duration delay;
  Timer? _timer;

  /// Applies [text] after [delay] of quiet; an empty text (field cleared)
  /// applies at once.
  void call(String text, void Function(String text) apply) {
    _timer?.cancel();
    if (text.isEmpty) {
      apply(text);
      return;
    }
    _timer = Timer(delay, () => apply(text));
  }

  /// Drops a pending text (the field closed or the page left).
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
