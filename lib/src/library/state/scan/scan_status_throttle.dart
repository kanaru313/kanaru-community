import 'dart:async';

import '../../domain/scan_status.dart';

/// Publishes scan status at most once per [interval] while a scan reports
/// progress; the newest progress value is always delivered (by a timer at
/// the end of the interval), and final states go out at once. A new
/// listener first receives the latest value.
class ScanStatusThrottle {
  ScanStatusThrottle({
    required this.interval,
    required this.clock,
    required this.timer,
  });

  final Duration interval;
  final DateTime Function() clock;
  final Timer Function(Duration, void Function()) timer;
  final StreamController<ScanStatus> _out = StreamController.broadcast();

  ScanStatus _latest = const ScanIdle();
  ScanStatus? _held;
  Timer? _heldTimer;
  DateTime? _lastEmit;
  bool _closed = false;

  Stream<ScanStatus> get stream {
    late StreamController<ScanStatus> c;
    StreamSubscription<ScanStatus>? sub;
    c = StreamController<ScanStatus>(
      onListen: () {
        c.add(_latest);
        sub = _out.stream.listen(c.add, onDone: c.close);
      },
      onCancel: () => sub?.cancel(),
    );
    return c.stream;
  }

  /// A running status: rate limited.
  void progress(ScanStatus status) {
    if (_closed) return;
    _latest = status;
    final last = _lastEmit;
    final now = clock();
    if (last == null || now.difference(last) >= interval) {
      _emit(status);
      return;
    }
    _held = status;
    _heldTimer ??= timer(interval - now.difference(last), () {
      _heldTimer = null;
      final held = _held;
      if (held != null && !_closed) _emit(held);
    });
  }

  /// A final status: published now, replacing any held progress.
  void finish(ScanStatus status) {
    if (_closed) return;
    _latest = status;
    _emit(status);
  }

  void _emit(ScanStatus status) {
    _held = null;
    _heldTimer?.cancel();
    _heldTimer = null;
    _lastEmit = clock();
    _out.add(status);
  }

  void dispose() {
    _closed = true;
    _heldTimer?.cancel();
    unawaited(_out.close());
  }
}
