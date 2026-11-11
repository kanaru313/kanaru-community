import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../platform/state/settings_providers.dart';
import 'playback_providers.dart';

final _log = Logger('playback.flush');

/// Flush hook: saves the session and the open listen, then the settings
/// store. Does nothing when the player was never created (a launch that did
/// not touch playback must not build it). Never waits on the command chain.
Future<void> playbackFlushHook(ProviderContainer container) async {
  if (!container.read(playerControllerProvider.exists)) return;
  final controller = container.read(playerControllerProvider);
  try {
    await controller.flushPlayback(listens: false);
  } on Object catch (e, st) {
    _log.warning('playback flush failed: $e', e, st);
  }
  // The position reaches the disk before the listen waits on the database.
  try {
    await container.read(settingsStoreProvider).flush();
  } on Object catch (e, st) {
    _log.warning('settings flush failed: $e', e, st);
  }
  try {
    await controller.flushListens();
  } on Object catch (e, st) {
    _log.warning('listen flush failed: $e', e, st);
  }
}

/// Before-exit hook: pauses playback so nothing advances or starts a new
/// track while the flush runs. May be cut by the exit limit and keep running,
/// which is harmless: a pause racing the flush only makes the saved state
/// more recent.
Future<void> pausePlaybackOnExitHook(ProviderContainer container) async {
  if (!container.read(playerControllerProvider.exists)) return;
  await container.read(playerControllerProvider).pause();
}
