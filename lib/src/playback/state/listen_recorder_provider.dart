import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../platform/domain/settings_store.dart';
import '../../platform/state/device_id_provider.dart';
import '../../platform/state/settings_providers.dart';
import '../domain/listen_accumulator.dart' show ListenRule;
import '../domain/playback_settings.dart';
import 'listen_recorder.dart';
import 'playback_data_providers.dart';
import 'session_restore.dart' show readSetting;

/// The one recorder of listens. The player feeds it and the history screens
/// clear through it; it lives as long as the container, so a player rebuild
/// never closes it under a clear.
final listenRecorderProvider = Provider<ListenRecorder>((ref) {
  final store = ref.read(settingsStoreProvider);
  final recorder = ListenRecorder(
    writer: ref.read(playLogWriterProvider),
    // Read when a listen is written, so a container without a device id
    // (a bare test) can still build the player.
    deviceId: () => ref.read(deviceIdProvider),
    // Read at each check, so a change applies to the next one.
    rule: () => readListenRule(store),
    historyEnabled: () => readSetting(store, historyEnabledSetting),
  );
  ref.onDispose(() => unawaited(recorder.close()));
  return recorder;
});

Object? _warnedListenRule;

/// The stored listen rule. A bad value reads as the default and is logged
/// once per distinct value, not at every check of every listen.
@visibleForTesting
ListenRule readListenRule(SettingsStore store) {
  final raw = store.read(listenRuleSetting.key);
  if (raw == null) return listenRuleSetting.defaultValue;
  try {
    return listenRuleSetting.decode(raw);
  } on Object catch (e) {
    if (_warnedListenRule != raw) {
      _warnedListenRule = raw;
      Logger('playback').warning('bad listen rule, using the default: $e');
    }
    return listenRuleSetting.defaultValue;
  }
}
