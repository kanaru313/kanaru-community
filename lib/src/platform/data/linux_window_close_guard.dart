import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import '../domain/window_close.dart';

final _log = Logger('platform.window_close');

/// The few `window_manager` calls the guard needs, so tests can fake them.
abstract interface class WindowManagerAdapter {
  Future<void> prepare();
  Future<void> setPreventClose();
  void onClose(void Function() handler);
  Future<void> hide();
  Future<void> destroy();
}

/// Real adapter over the static [windowManager].
class PluginWindowManagerAdapter
    with WindowListener
    implements WindowManagerAdapter {
  void Function()? _handler;

  @override
  Future<void> prepare() => windowManager.ensureInitialized();

  @override
  Future<void> setPreventClose() => windowManager.setPreventClose(true);

  @override
  void onClose(void Function() handler) {
    _handler = handler;
    windowManager.addListener(this);
  }

  @override
  void onWindowClose() => _handler?.call();

  @override
  Future<void> hide() => windowManager.hide();

  @override
  Future<void> destroy() => windowManager.destroy();
}

/// Linux: the window manager plugin disconnects the engine's close handler,
/// so `AppLifecycleListener.onExitRequested` never fires. The guard prevents
/// the close, hides the window, runs the flush, destroys the window and ends
/// the process.
class LinuxWindowCloseGuard implements WindowCloseGuard {
  LinuxWindowCloseGuard({
    WindowManagerAdapter? window,
    void Function(int code)? exit,
    this.destroyTimeout = const Duration(seconds: 1),
  }) : _window = window ?? PluginWindowManagerAdapter(),
       _exit = exit ?? io.exit;

  final WindowManagerAdapter _window;
  final void Function(int code) _exit;
  final Duration destroyTimeout;

  Future<void> Function()? _beforeClose;
  bool _flushing = false;
  bool _destroying = false;

  @override
  Future<void> install(Future<void> Function() beforeClose) async {
    if (_beforeClose != null) return;
    _beforeClose = beforeClose;
    try {
      await _window.prepare();
      // The listener goes first, so a prevented close always has a handler.
      _window.onClose(() => unawaited(_onClose()));
      await _window.setPreventClose();
    } catch (error, stack) {
      _log.warning('window close guard not installed', error, stack);
    }
  }

  Future<void> _onClose() async {
    if (_destroying) return; // echo of destroy()
    if (_flushing) {
      _exit(0); // the user insists
      return;
    }
    _flushing = true;
    // Not awaited: the window disappearing must not wait for the compositor.
    unawaited(
      _window.hide().catchError((Object e) {
        _log.warning('could not hide the window (${e.runtimeType})');
      }),
    );
    try {
      await _beforeClose!();
    } catch (error, stack) {
      _log.warning('before-close work failed', error, stack);
    }
    _destroying = true;
    try {
      await _window.destroy().timeout(destroyTimeout);
    } catch (error) {
      _log.warning('window destroy failed (${error.runtimeType})');
    }
    _exit(0);
  }
}
