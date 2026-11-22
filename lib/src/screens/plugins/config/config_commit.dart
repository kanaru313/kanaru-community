import 'dart:async';

import '../../../plugins/state/config_form_provider.dart' show ConfigWrite;

/// Sends one value of one field to the store.
typedef ConfigSend = Future<ConfigWrite> Function(Object? value);

/// The save of one field: one write in flight, the latest value submitted
/// meanwhile waits and goes next (older waiting ones are dropped). The queue
/// outlives its editor: [detach] only stops the notifications, a save under
/// way or waiting still completes, so leaving the page with a field still
/// focused saves its last edit.
class ConfigCommit {
  ConfigCommit(this._send, {this._onChanged});

  final ConfigSend _send;
  void Function()? _onChanged;

  /// Why the latest save was refused; null while none was, and after a save
  /// went through. A refusal that a newer waiting value replaces is not
  /// reported.
  ConfigWrite? refusal;

  bool _saving = false;
  bool _hasWaiting = false;
  Object? _waiting;
  Completer<void>? _idle;

  /// A save is under way or waiting.
  bool get busy => _saving || _hasWaiting;

  /// Saves [value] now, or after the save under way.
  void submit(Object? value) {
    if (_saving) {
      _waiting = value;
      _hasWaiting = true;
      return;
    }
    _run(value);
  }

  /// Forgets the refusal (the user is editing again).
  void dismiss() {
    if (refusal == null) return;
    refusal = null;
    _onChanged?.call();
  }

  /// Completes when nothing is under way or waiting.
  Future<void> get idle {
    if (!busy) return Future.value();
    return (_idle ??= Completer<void>()).future;
  }

  /// Stops notifying the editor (it is gone). Saves still finish.
  void detach() => _onChanged = null;

  Future<void> _run(Object? value) async {
    _saving = true;
    ConfigWrite result;
    try {
      result = await _send(value);
    } on Object {
      // The facade never throws; a surprise is a failed write, not a crash.
      result = ConfigWrite.failed;
    }
    _saving = false;
    final next = _hasWaiting;
    final nextValue = _waiting;
    _hasWaiting = false;
    _waiting = null;
    if (next) {
      // The waiting value replaces this result; it reports its own.
      _run(nextValue);
      return;
    }
    refusal = result == ConfigWrite.written ? null : result;
    _onChanged?.call();
    final idle = _idle;
    _idle = null;
    if (idle != null && !idle.isCompleted) idle.complete();
  }
}
