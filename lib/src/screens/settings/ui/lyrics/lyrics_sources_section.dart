import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/domain/online/lyrics_source.dart';
import '../../../../lyrics/state/online/lyrics_sources_provider.dart';
import '../../../../lyrics/ui/lyrics_settings_link.dart';
import '../../../../lyrics/ui/online/online_labels.dart';
import '../../../../lyrics/ui/online/plugin_avatar.dart';

/// "Nguồn lời trực tuyến": the lyrics plugins in the order the automatic
/// search asks them, each with its switch. Reorder and switches apply at once.
class LyricsSourcesSection extends ConsumerWidget {
  const LyricsSourcesSection({super.key});

  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loaded = ref.watch(lyricsSourcesLoadedProvider);
    final sources = loaded
        ? ref.watch(lyricsSourcesProvider)
        : const <LyricsSource>[];
    final actions = ref.read(lyricsSourceActionsProvider);
    final on = sources.where((s) => s.enabled).length;
    return SetupSection(
      title: Text(l10n.lyricsSettingsSources),
      subtitle: sources.isEmpty
          ? null
          : Text(l10n.lyricsSettingsSourcesCount(on, sources.length)),
      hint: l10n.lyricsSettingsSourcesHint,
      hintTooltip: l10n.settingsSectionHintTooltip(l10n.lyricsSettingsSources),
      hintTitle: l10n.lyricsSettingsSources,
      children: [
        if (sources.isNotEmpty)
          ReorderableToggleList<String>(
            dragLabel: l10n.lyricsSettingsSourceDrag,
            keepOneOn: false,
            items: [for (final s in sources) _item(context, l10n, s)],
            onReorder: actions.reorder,
            onToggle: (id, enabled) {
              final name = sources.firstWhere((s) => s.id == id).name;
              actions.setEnabled(id, enabled);
              _toast(
                context,
                enabled
                    ? l10n.lyricsSettingsSourceOnToast(name)
                    : l10n.lyricsSettingsSourceOffToast(name),
              );
            },
          ),
        SetupAddRow(
          icon: KIcons.add,
          label: Text(l10n.lyricsSettingsAddSource),
          onTap: () => context.push(lyricsPluginStoreLocation),
        ),
      ],
    );
  }

  ReorderableToggleItem<String> _item(
    BuildContext context,
    AppLocalizations l10n,
    LyricsSource s,
  ) {
    final base = switch (s.origin) {
      LyricsSourceOrigin.repo => l10n.lyricsSettingsSourceRepo(s.version),
      LyricsSourceOrigin.file => l10n.lyricsSettingsSourceFile(s.version),
      LyricsSourceOrigin.link => l10n.lyricsSettingsSourceLink(s.version),
    };
    final problem = switch (s.problem) {
      null => null,
      SourceProblem.needsConfig => l10n.lyricsSettingsSourceNeedsConfig,
      SourceProblem.broken => l10n.lyricsSettingsSourceBroken,
      SourceProblem.paused => l10n.lyricsSettingsSourcePaused(
        s.pausedUntil == null ? '' : formatClock(context, s.pausedUntil!),
      ),
    };
    return ReorderableToggleItem<String>(
      value: s.id,
      title: Text(s.name),
      enabled: s.enabled,
      switchLabel: l10n.lyricsSettingsSourceSwitch(s.name),
      leading: PluginAvatar(providerId: s.id, name: s.name, size: _iconSize),
      subtitle: s.enabled ? base : l10n.lyricsSettingsSourceOff(base),
      problem: problem,
      onProblemTap: problem == null
          ? null
          : () => context.push(lyricsPluginPageLocation(s.id)),
    );
  }

  /// The messenger may be missing in a bare host; the change is made anyway.
  void _toast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) showAppSnackBarOn(messenger, message);
  }
}
