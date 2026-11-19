import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/domain/scan_status.dart';
import '../../../../library/state/scan/library_counts_provider.dart';
import '../../../../library/state/scan_providers.dart';
import '../../../../library/ui/scan/scan_card_state.dart';
import '../../../first_run/ui/folder_actions.dart';
import '../settings_scaffold.dart';

/// Head of Settings › Library: what the library holds with a "Rescan" button,
/// the time of the last scan of this session, or the scan progress card while
/// tags and covers are read.
class LibraryOverviewCard extends ConsumerWidget {
  const LibraryOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(scanStatusProvider).value;
    final card = scanCardStateOf(status, DateTime.now());
    if (card is ScanCardProgress) {
      return ProgressNoticeCard(
        icon: KIcons.rescan,
        title: Text(l10n.scanHomeScanning),
        subtitle: Text(l10n.scanHomeProgress(card.done, card.total)),
        progress: card.progress,
      );
    }
    final counts = ref.watch(libraryOverviewProvider).value;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final last = status is ScanFinished ? status : null;
    return SettingsBlock(
      children: [
        Padding(
          padding: const EdgeInsets.all(KSpace.x4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // One line per count; a single "—" until the counts load.
                    for (final line
                        in counts == null
                            ? const ['—']
                            : [
                                l10n.settingsLibraryTracksCount(counts.tracks),
                                l10n.settingsLibraryAlbumsCount(counts.albums),
                                l10n.settingsLibraryArtistsCount(
                                  counts.artists,
                                ),
                              ])
                      Text(line, style: textTheme.titleMedium),
                    if (last != null)
                      Text(
                        l10n.settingsLibraryLastScan(
                          _clock(last.at.toLocal()),
                          last.added,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const KGap(KSpace.x3),
              FilledButton.tonalIcon(
                onPressed: () {
                  rescanInBackground(ref.read(libraryScanCommandsProvider));
                  showAppSnackBar(context, l10n.settingsLibraryRescanning);
                },
                icon: const Icon(KIcons.rescan),
                label: Text(l10n.scanSetupRescan),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "09:05": 24-hour time, as the spec writes it.
  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
