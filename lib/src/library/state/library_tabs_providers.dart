import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/domain/setting.dart';
import '../../platform/state/settings_providers.dart';
import '../domain/library_tabs.dart';

/// Settings key `library.tabs`.
final Setting<LibraryTabsConfig> libraryTabsSetting = Setting(
  'library.tabs',
  LibraryTabsConfig.defaults,
  decode: LibraryTabsConfig.fromJson,
  encode: (c) => c.toJson(),
);

/// Order and visibility of the library tabs.
class LibraryTabsNotifier extends SettingNotifier<LibraryTabsConfig> {
  LibraryTabsNotifier() : super(libraryTabsSetting);

  /// See [LibraryTabsConfig.reorder] for the meaning of [to].
  Future<void> reorder(int from, int to) async => set(state.reorder(from, to));

  /// Throws [StateError] when disabling the last enabled tab.
  Future<void> setEnabled(LibraryTab tab, bool enabled) async =>
      set(state.withEnabled(tab, enabled));
}

final libraryTabsProvider =
    NotifierProvider<LibraryTabsNotifier, LibraryTabsConfig>(
      LibraryTabsNotifier.new,
    );
