import 'dart:async';

import '../../domain/media_controls.dart';

/// How long a command that nobody listened to yet stays worth replaying.
const bufferedCommandMaxAge = Duration(seconds: 10);

/// The `commands` stream of a platform implementation. A command that
/// arrives before the player attaches (Android can start the service from a
/// headset button before the app has built anything) is kept, the last one
/// only, and replayed to the first listener if it is younger than
/// [bufferedCommandMaxAge].
class CommandBuffer {
  CommandBuffer({DateTime Function()? clock}) : _now = clock ?? DateTime.now {
    _controller = StreamController<MediaCommand>(
      onListen: _replay,
      onCancel: () => _listening = false,
    );
  }

  final DateTime Function() _now;
  late final StreamController<MediaCommand> _controller;
  bool _listening = false;
  MediaCommand? _held;
  DateTime? _heldAt;

  Stream<MediaCommand> get stream => _controller.stream;

  void add(MediaCommand command) {
    if (_controller.isClosed) return;
    if (_listening) {
      _controller.add(command);
    } else {
      _held = command;
      _heldAt = _now();
    }
  }

  void _replay() {
    _listening = true;
    final held = _held;
    final at = _heldAt;
    _held = null;
    _heldAt = null;
    if (held != null &&
        at != null &&
        _now().difference(at) < bufferedCommandMaxAge) {
      _controller.add(held);
    }
  }

  Future<void> close() => _controller.close();
}
