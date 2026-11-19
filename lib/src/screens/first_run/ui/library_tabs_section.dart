import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/library_tabs.dart';
import '../../../library/state/library_tabs_providers.dart';
import 'setup_mode.dart';

final _log = Logger('screens.first_run');

String _tabName(AppLocalizations l10n, LibraryTab tab) => switch (tab) {
  LibraryTab.songs => l10n.libraryTabSongs,
  LibraryTab.albums => l10n.libraryTabAlbums,
  LibraryTab.artists => l10n.libraryTabArtists,
  LibraryTab.genres => l10n.libraryTabGenres,
  LibraryTab.languages => l10n.libraryTabLanguages,
  LibraryTab.folders => l10n.libraryTabFolders,
};

/// The six library tabs: switch each on or off, drag to reorder. The last
/// enabled tab cannot be switched off. In [SetupMode.settings] the caption
/// also says where tabs show on this shell.
class LibraryTabsSection extends ConsumerWidget {
  const LibraryTabsSection({super.key, this.mode = SetupMode.firstRun});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(libraryTabsProvider);
    final notifier = ref.read(libraryTabsProvider.notifier);
    final settingsHint = FormFactor.of(context) == FormFactor.desktop
        ? l10n.settingsLibraryTabsHintDesktop
        : l10n.settingsLibraryTabsHintMobile;
    return captionedSection(
      context,
      mode: mode,
      title: l10n.scanSetupTabsTitle,
      caption: mode == SetupMode.settings
          ? settingsHint
          : l10n.scanSetupTabsHint,
      children: [
        ReorderableToggleList<LibraryTab>(
          dragLabel: l10n.scanSetupTabDrag,
          lockedLabel: l10n.scanSetupTabLocked,
          items: [
            for (final tab in config.order)
              ReorderableToggleItem(
                value: tab,
                title: Text(_tabName(l10n, tab)),
                enabled: config.enabled.contains(tab),
                switchLabel: l10n.scanSetupTabShow(_tabName(l10n, tab)),
              ),
          ],
          onReorder: (from, to) => notifier.reorder(from, to),
          onToggle: (tab, on) async {
            try {
              await notifier.setEnabled(tab, on);
            } on StateError catch (e) {
              // The list locks the last enabled tab; this is a late guard.
              _log.warning('tab switch refused: ${e.message}');
            }
          },
        ),
      ],
    );
  }
}
