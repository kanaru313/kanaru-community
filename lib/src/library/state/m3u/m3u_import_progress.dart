import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/m3u/m3u_results.dart';

/// How long an import runs before its card shows: shorter imports finish
/// with their toast or report and never flash a card.
const m3uProgressDelay = Duration(seconds: 1);

/// UI-facing progress updates come at most this often (a 50 000-line file
/// reports about 1 600 batches).
const m3uProgressCoalesce = Duration(milliseconds: 100);

/// What the progress card shows. [visible] turns true once the import has run
/// for [m3uProgressDelay].
class M3uImportProgressView {
  const M3uImportProgressView({
    required this.fileName,
    required this.done,
    required this.total,
    required this.visible,
  });

  final String fileName;
  final int done;

  /// Null while the file is still being read.
  final int? total;
  final bool visible;

  M3uImportProgressView _with({int? done, int? total, bool? visible}) =>
      M3uImportProgressView(
        fileName: fileName,
        done: done ?? this.done,
        total: total ?? this.total,
        visible: visible ?? this.visible,
      );

  @override
  bool operator ==(Object other) =>
      other is M3uImportProgressView &&
      other.fileName == fileName &&
      other.done == done &&
      other.total == total &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(fileName, done, total, visible);
}

/// Progress of the running M3U import, app-wide: the import outlives the page
/// that started it. Null when no import runs.
class M3uImportProgressNotifier extends Notifier<M3uImportProgressView?> {
  Timer? _showTimer;

  /// Open while updates are being throttled; null when the next update may
  /// be applied at once.
  Timer? _gate;
  M3uImportProgress? _pending;

  @override
  M3uImportProgressView? build() {
    ref.onDispose(_cancelTimers);
    return null;
  }

  /// An import of [fileName] started (the document was picked, so the system
  /// dialog's time never counts). The card stays hidden for
  /// [m3uProgressDelay].
  void begin(String fileName) {
    _cancelTimers();
    state = M3uImportProgressView(
      fileName: fileName,
      done: 0,
      total: null,
      visible: false,
    );
    _showTimer = Timer(m3uProgressDelay, () {
      _showTimer = null;
      final current = state;
      if (current != null) state = current._with(visible: true);
    });
  }

  /// Reading or matching moved on. At most one change per
  /// [m3uProgressCoalesce]; the last one is always applied.
  void update(M3uImportProgress progress) {
    if (!ref.mounted || state == null) return;
    if (_gate != null) {
      _pending = progress;
      return;
    }
    _apply(progress);
    _gate = Timer(m3uProgressCoalesce, _gateElapsed);
  }

  void _gateElapsed() {
    final pending = _pending;
    _pending = null;
    if (pending == null || state == null) {
      _gate = null;
      return;
    }
    _apply(pending);
    _gate = Timer(m3uProgressCoalesce, _gateElapsed);
  }

  void _apply(M3uImportProgress p) {
    final current = state;
    if (current == null) return;
    // A null total (file still being read) never replaces a known one.
    state = current._with(done: p.done, total: p.total);
  }

  /// The import is over (any outcome). Called before the result is shown, so
  /// the card never sits next to its toast or report.
  void end() {
    _cancelTimers();
    // A flow that outlives the container ends quietly.
    if (ref.mounted) state = null;
  }

  void _cancelTimers() {
    _showTimer?.cancel();
    _showTimer = null;
    _gate?.cancel();
    _gate = null;
    _pending = null;
  }
}

final m3uImportProgressProvider =
    NotifierProvider<M3uImportProgressNotifier, M3uImportProgressView?>(
      M3uImportProgressNotifier.new,
    );
