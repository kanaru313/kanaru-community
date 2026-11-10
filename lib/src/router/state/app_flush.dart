import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../extension/state/extension_providers.dart';
import '../../platform/state/settings_providers.dart';

final _log = Logger('app.flush');

/// Longest the app waits for the flush work when it is asked to exit, and
/// longest a running flush is still joined by a later request.
const exitFlushCap = Duration(seconds: 2);

/// A flush that started earlier than this is not trusted to include state
/// changed since: an exit request runs one more flush after it.
const flushFreshWindow = Duration(milliseconds: 250);

/// Writes pending state to disk: the settings store first, then every flush
/// hook of the registry in order. A failing step is logged and does not stop
/// the others.
Future<void> flushApp(ProviderContainer container) async {
  try {
    await container.read(settingsStoreProvider).flush();
  } catch (error, stack) {
    _log.warning('settings flush failed', error, stack);
  }
  for (final hook in container.read(extensionRegistryProvider).flushHooks) {
    try {
      await hook(container);
    } catch (error, stack) {
      _log.warning('flush hook failed', error, stack);
    }
  }
}

class _Run {
  _Run(this.future);
  final Future<void> future;
  bool stale = false;
  bool old = false;
  Timer? staleTimer;
  Timer? oldTimer;

  void cancel() {
    staleTimer?.cancel();
    oldTimer?.cancel();
  }
}

/// Shares one running flush between callers (`hidden` is followed by
/// `paused` straight away) without letting a hung hook block later flushes:
/// a run older than [cap] is no longer joined, a fresh one starts instead.
class FlushCoordinator {
  FlushCoordinator({
    this.cap = exitFlushCap,
    this.freshWindow = flushFreshWindow,
    Future<void> Function(ProviderContainer)? flush,
  }) : _flush = flush ?? flushApp;

  final Duration cap;
  final Duration freshWindow;
  final Future<void> Function(ProviderContainer) _flush;
  _Run? _current;

  /// Starts a flush, or joins the running one while it is younger than [cap].
  Future<void> flush(ProviderContainer container) => _join(container).future;

  _Run _join(ProviderContainer container) {
    final running = _current;
    if (running != null && !running.stale) return running;
    late final _Run run;
    run = _Run(
      _flush(container).whenComplete(() {
        run.cancel();
        if (identical(_current, run)) _current = null;
      }),
    );
    run
      ..staleTimer = Timer(cap, () => run.stale = true)
      ..oldTimer = Timer(freshWindow, () => run.old = true);
    return _current = run;
  }

  /// Flush for an exit request, capped at [cap] in total. Joining a run that
  /// started more than [freshWindow] ago is followed by one more flush so
  /// state changed in between is written too.
  Future<void> flushForExit(ProviderContainer container) async {
    try {
      await (() async {
        final run = _join(container);
        final joinedOld = run.old;
        await run.future;
        if (joinedOld) await _join(container).future;
      })().timeout(cap);
    } on TimeoutException {
      _log.warning('flush on exit hit the ${cap.inMilliseconds} ms cap');
    } on Object catch (error, stack) {
      _log.warning('flush on exit failed', error, stack);
    }
  }

  void dispose() {
    _current?.cancel();
    _current = null;
  }
}
