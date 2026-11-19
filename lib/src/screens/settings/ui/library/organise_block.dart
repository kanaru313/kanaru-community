import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/state/browse/list_prefs_providers.dart';
import '../soon_row.dart';

/// Block "Organise": how the library is arranged.
class OrganiseBlock extends ConsumerWidget {
  const OrganiseBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final compact = ref.watch(compactFoldersProvider);
    return SetupSection(
      title: Text(l10n.settingsLibraryBlockOrganise),
      children: [
        KSwitchRow(
          leading: const Icon(KIcons.folders),
          title: Text(l10n.settingsLibraryMergeFolders),
          subtitle: Text(l10n.settingsLibraryMergeFoldersDesc),
          switchLabel: l10n.settingsLibraryMergeFolders,
          value: compact,
          onChanged: (v) => ref.read(compactFoldersProvider.notifier).set(v),
        ),
        // The artist split and language source rows go here, before the
        // "coming soon" rows (those stay last in the block).
        SoonRow(
          icon: KIcons.albums,
          title: Text(l10n.settingsLibraryAlbumGrouping),
        ),
      ],
    );
  }
}

/// Block "Removed": the tracks the user took out of the library. Not built
/// yet: a "coming soon" row.
class RemovedBlock extends StatelessWidget {
  const RemovedBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.settingsLibraryBlockRemoved),
      children: [
        SoonRow(
          icon: KIcons.hideFromLibrary,
          title: Text(l10n.settingsLibraryRemoved),
        ),
      ],
    );
  }
}
