import '../../domain/media_controls.dart';

/// No system controls (tests, platforms without them). Grants focus.
class NoopMediaControls implements MediaControls {
  const NoopMediaControls();

  @override
  Future<void> start() async {}

  @override
  Future<void> update(MediaControlsItem? item, MediaControlsState state) async {}

  @override
  void updatePosition(Duration position) {}

  @override
  void seeked(Duration position) {}

  @override
  Stream<MediaCommand> get commands => const Stream.empty();

  @override
  Future<bool> activate() async => true;

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dispose() async {}
}
