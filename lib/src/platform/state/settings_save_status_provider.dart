import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/settings_save_status.dart';
import 'settings_providers.dart';

/// `true` while the settings file cannot be written. Always `false` for a
/// store that does not report it (for example the in-memory one).
final settingsSaveFailingProvider = StreamProvider<bool>((ref) async* {
  final store = ref.watch(settingsStoreProvider);
  if (store is! SettingsSaveStatus) {
    yield false;
    return;
  }
  final status = store as SettingsSaveStatus;
  yield status.isFailing;
  yield* status.saveFailing;
});
