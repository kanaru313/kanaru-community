import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../platform/state/settings_providers.dart';
import 'playback_providers.dart';
import 'saved_queue_recorder_provider.dart';

final _log = Logger('playback.flush');

/// Flush hook: saves the session and the open listen, then the settings
/// store. Does nothing when the player was never created (a launch that did
/// not touch playback must not build it). Never waits on the command chain.
Future<void> playbackFlushHook(
  ProviderContainer container, {
  @visibleForTesting Duration savedQueueWait = _savedQueueWait,
}) async {
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
  // A replace that already left the command chain finishes its save before
  // the app exits; one still waiting in the chain is not saved.
  if (container.read(savedQueueRecorderProvider.exists)) {
    try {
      await container
          .read(savedQueueRecorderProvider)
          .idle
          .timeout(savedQueueWait);
    } on TimeoutException {
      _log.warning('saved queue write still running at exit');
    } on Object catch (e, st) {
      _log.warning('saved queue flush failed: $e', e, st);
    }
  }
}

/// How long the flush waits for a saved-queue write. On exit the whole flush
/// is cut at `exitFlushCap` (also 2 s) first, so this only bounds the flushes
/// that run when the app goes to the background.
const _savedQueueWait = Duration(seconds: 2);

/// Before-exit hook: pauses playback so nothing advances or starts a new
/// track while the flush runs. May be cut by the exit limit and keep running,
/// which is harmless: a pause racing the flush only makes the saved state
/// more recent.
Future<void> pausePlaybackOnExitHook(ProviderContainer container) async {
  if (!container.read(playerControllerProvider.exists)) return;
  await container.read(playerControllerProvider).pause();
}
