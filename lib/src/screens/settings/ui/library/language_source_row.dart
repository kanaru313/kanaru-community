import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/domain/scan/read_rules.dart';
import '../../../../library/state/scan/read_rules_settings.dart';
import '../../../../library/state/scan_providers.dart';
import 'read_rules_rescan.dart';

/// "Language source" row: where a song's language comes from. A change
/// re-reads the library in the background.
class LanguageSourceRow extends ConsumerStatefulWidget {
  const LanguageSourceRow({super.key});

  @override
  ConsumerState<LanguageSourceRow> createState() => _LanguageSourceRowState();
}

class _LanguageSourceRowState extends ConsumerState<LanguageSourceRow> {
  final _anchor = GlobalKey();

  static String _name(AppLocalizations l10n, LanguageSource s) => switch (s) {
    LanguageSource.tagThenDetected => l10n.settingsLibraryLanguageBoth,
    LanguageSource.tagOnly => l10n.settingsLibraryLanguageTag,
    LanguageSource.detectedOnly => l10n.settingsLibraryLanguageDetected,
  };

  static String _desc(AppLocalizations l10n, LanguageSource s) => switch (s) {
    LanguageSource.tagThenDetected => l10n.settingsLibraryLanguageBothDesc,
    LanguageSource.tagOnly => l10n.settingsLibraryLanguageTagDesc,
    LanguageSource.detectedOnly => l10n.settingsLibraryLanguageDetectedDesc,
  };

  Future<void> _pick(AppLocalizations l10n, LanguageSource current) async {
    // Taken before the await: the picker may outlive this row.
    final notifier = ref.read(languageSourceProvider.notifier);
    final scan = ref.read(libraryScanCommandsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final chosen = await showSelectionPicker<LanguageSource>(
      context,
      anchor: _anchor,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.settingsLibraryLanguageSource),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(KSpace.x4, 0, KSpace.x4, KSpace.x2),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          child: Text(l10n.settingsLibraryLanguageSourceCaption),
        ),
      ),
      selected: current,
      options: [
        for (final s in LanguageSource.values)
          SelectionOption(
            value: s,
            title: Text(_name(l10n, s)),
            // The reader detects a language only for files that have no
            // language tag, so "detection only" cannot work yet: shown, dimmed.
            enabled: s != LanguageSource.detectedOnly,
            subtitle: Text(
              s == LanguageSource.detectedOnly
                  ? '${_desc(l10n, s)} · ${l10n.appComingSoon}'
                  : _desc(l10n, s),
            ),
          ),
      ],
    );
    if (chosen == null || chosen == current) return;
    await notifier.set(chosen);
    rescanForReadRules(scan);
    showAppSnackBarOn(messenger, l10n.settingsLibraryRescanning);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final source = ref.watch(languageSourceProvider);
    return SetupValueRow(
      anchorKey: _anchor,
      icon: KIcons.languages,
      title: Text(l10n.settingsLibraryLanguageSource),
      value: Text(_name(l10n, source)),
      onTap: () => _pick(l10n, source),
    );
  }
}
