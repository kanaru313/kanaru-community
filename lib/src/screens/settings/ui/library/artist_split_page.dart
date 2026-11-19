import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/domain/scan/read_rules.dart';
import '../../../../library/state/scan/read_rules_settings.dart';
import '../../../../library/state/scan_providers.dart';
import '../../../../platform/state/settings_providers.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'artist_split_example.dart';
import 'read_rules_rescan.dart';

/// A word entry shows its spaces as `␣`; a symbol entry is shown as it is.
String _display(String entry) => isWordSeparator(entry) ? '␣$entry␣' : entry;

/// Settings › Library › Split artists: the separators, the names kept whole
/// and a restore row. Every change re-reads the library in the background.
class ArtistSplitPage extends ConsumerWidget {
  const ArtistSplitPage({super.key});

  String _problem(AppLocalizations l10n, SplitEntryProblem p) => switch (p) {
    SplitEntryProblem.empty => l10n.settingsArtistSplitErrEmpty,
    SplitEntryProblem.duplicate => l10n.settingsArtistSplitErrDuplicate,
    SplitEntryProblem.tooLong => l10n.settingsArtistSplitErrTooLong(
      maxSplitEntryLength,
    ),
    SplitEntryProblem.listFull => l10n.settingsArtistSplitErrFull(
      maxSplitEntries,
    ),
  };

  /// Adds [raw] to the list of [provider]; returns the message to show when
  /// the entry check refuses it. [clean] is the same check the stored list
  /// goes through when it is read.
  String? _add(
    WidgetRef ref,
    AppLocalizations l10n,
    NotifierProvider<SettingNotifier<List<String>>, List<String>> provider, {
    required String Function(String, {Iterable<String> existing}) clean,
    required bool isSeparator,
    required String raw,
  }) {
    final current = ref.read(provider);
    final String entry;
    try {
      entry = clean(raw, existing: current);
    } on SplitEntryException catch (e) {
      return _problem(l10n, e.problem);
    }
    ref.read(provider.notifier).set([...current, entry]);
    rescanForReadRules(ref.read(libraryScanCommandsProvider));
    final group = isSeparator && (entry == ',' || entry == '&');
    showAppSnackBar(
      ref.context,
      group
          ? l10n.settingsArtistSplitAddedGroup(entry)
          : l10n.settingsArtistSplitAdded(entry),
    );
    return null;
  }

  void _remove(
    WidgetRef ref,
    AppLocalizations l10n,
    NotifierProvider<SettingNotifier<List<String>>, List<String>> provider,
    String entry,
  ) {
    final current = ref.read(provider);
    ref.read(provider.notifier).set([
      for (final e in current)
        if (e != entry) e,
    ]);
    rescanForReadRules(ref.read(libraryScanCommandsProvider));
    showAppSnackBar(ref.context, l10n.settingsArtistSplitRemoved(entry));
  }

  Future<void> _reset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // Everything the answer needs is taken before the dialog opens.
    final separators = ref.read(artistSeparatorsProvider.notifier);
    final keep = ref.read(artistKeepWholeProvider.notifier);
    final scan = ref.read(libraryScanCommandsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmAction(
      context,
      title: l10n.settingsArtistSplitResetTitle,
      message: l10n.settingsArtistSplitResetBody,
      confirmLabel: l10n.settingsArtistSplitResetConfirm,
    );
    if (!ok) return;
    await separators.set(defaultArtistSeparators);
    await keep.set(defaultArtistKeepWhole);
    rescanForReadRules(scan);
    showAppSnackBarOn(messenger, l10n.settingsArtistSplitRestored);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final separators = ref.watch(artistSeparatorsProvider);
    final keep = ref.watch(artistKeepWholeProvider);
    final rules = ref.watch(currentReadRulesProvider);
    final isDefault =
        listEquals(separators, defaultArtistSeparators) &&
        listEquals(keep, defaultArtistKeepWhole);
    return SettingsScaffold(
      title: l10n.settingsLibraryArtistSplit,
      parentPath: SettingsPaths.library,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
          child: Text(
            l10n.settingsArtistSplitIntro,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        ArtistSplitExampleCard(rules: rules),
        SetupSection(
          title: Text(l10n.settingsArtistSplitSeparators),
          hint: l10n.settingsArtistSplitSeparatorsHint,
          hintTooltip: l10n.settingsSectionHintTooltip(
            l10n.settingsArtistSplitSeparators,
          ),
          hintTitle: l10n.settingsArtistSplitSeparators,
          children: [
            Padding(
              padding: const EdgeInsets.all(KSpace.x4),
              child: KChipEditor(
                values: separators,
                suggestions: const ['with'],
                display: _display,
                inputHint: l10n.settingsArtistSplitSeparatorInput,
                addLabel: l10n.settingsArtistSplitAdd,
                emptyNote: l10n.settingsArtistSplitNoSeparators,
                removeTooltip: l10n.settingsArtistSplitRemove,
                onAdd: (raw) => _add(
                  ref,
                  l10n,
                  artistSeparatorsProvider,
                  clean: cleanSeparator,
                  isSeparator: true,
                  raw: raw,
                ),
                onRemove: (v) =>
                    _remove(ref, l10n, artistSeparatorsProvider, v),
              ),
            ),
          ],
        ),
        SetupSection(
          title: Text(l10n.settingsArtistSplitKeep),
          hint: l10n.settingsArtistSplitKeepHint,
          hintTooltip: l10n.settingsSectionHintTooltip(
            l10n.settingsArtistSplitKeep,
          ),
          hintTitle: l10n.settingsArtistSplitKeep,
          children: [
            Padding(
              padding: const EdgeInsets.all(KSpace.x4),
              child: KChipEditor(
                values: keep,
                inputHint: l10n.settingsArtistSplitKeepInput,
                addLabel: l10n.settingsArtistSplitAdd,
                removeTooltip: l10n.settingsArtistSplitRemove,
                onAdd: (raw) => _add(
                  ref,
                  l10n,
                  artistKeepWholeProvider,
                  clean: cleanKeepWhole,
                  isSeparator: false,
                  raw: raw,
                ),
                onRemove: (v) => _remove(ref, l10n, artistKeepWholeProvider, v),
              ),
            ),
          ],
        ),
        SettingsBlock(
          children: [
            KListRow(
              leading: const Icon(KIcons.reset),
              title: Text(l10n.settingsArtistSplitReset),
              subtitle: Text(
                isDefault
                    ? l10n.settingsArtistSplitResetIsDefault
                    : l10n.settingsArtistSplitResetTo(
                        defaultArtistSeparators.length,
                        defaultArtistKeepWhole.join(', '),
                      ),
              ),
              enabled: !isDefault,
              onTap: () => _reset(context, ref, l10n),
            ),
          ],
        ),
      ],
    );
  }
}
