import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/settings_save_status.dart';
import 'settings_providers.dart';

/// `true` while the settings file cannot be written. Always `false` for a
/// store that does not report it (for example the in-memory one).
final settingsSaveFailingProvider = StreamProvider<bool>((ref) {
  final store = ref.watch(settingsStoreProvider);
  if (store is! SettingsSaveStatus) return Stream.value(false);
  final status = store as SettingsSaveStatus;
  // Subscribe first, then emit the current value: the change stream is
  // broadcast and does not buffer, so a flip between the read and the
  // subscription would be lost.
  return Stream<bool>.multi((controller) {
    final sub = status.saveFailing.listen(
      controller.addSync,
      onError: controller.addErrorSync,
    );
    controller.addSync(status.isFailing);
    controller.onCancel = sub.cancel;
  });
});
