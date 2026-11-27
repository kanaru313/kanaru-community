import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/settings/tool_groups.dart';
import '../../../../ai/domain/variables/variable_catalog.dart';
import '../../../../ai/state/ai_settings_providers.dart';
import '../../../../platform/state/settings_providers.dart';
import '../../../../playback/state/playback_settings_providers.dart';
import 'ai_catalog_labels.dart';

final _log = Logger('settings.ai_tools');

/// "Công cụ": one switch per privacy group of the assistant's tools (read
/// groups, then the groups that change something), then the switch that lets
/// variables fill from a group that is off. Every switch applies at once.
class AiToolsSection extends ConsumerWidget {
  const AiToolsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.aiSetToolsTitle;
    final historyOn = ref.watch(historyEnabledProvider);
    final bypass = ref.watch(aiVarBypassProvider);
    return SetupSection(
      title: Text(title),
      hint: l10n.aiSetToolsHint,
      hintTooltip: l10n.settingsSectionHintTooltip(title),
      hintTitle: title,
      children: [
        _GroupLabel(l10n.aiSetToolsGroupRead),
        for (final g in AiToolGroup.values.where((g) => !g.isWrite))
          _ToolRow(
            group: g,
            locked: g == AiToolGroup.listeningStats && !historyOn,
          ),
        _GroupLabel(l10n.aiSetToolsGroupWrite),
        for (final g in AiToolGroup.values.where((g) => g.isWrite))
          _ToolRow(group: g),
        const Divider(indent: KSpace.x4, endIndent: KSpace.x4),
        KSwitchRow(
          leading: const Icon(KIcons.tag),
          title: Text(l10n.aiSetVarBypassTitle),
          subtitle: Text(l10n.aiSetVarBypassDesc),
          switchLabel: l10n.aiSetVarBypassTitle,
          value: bypass,
          onChanged: (v) => _save(ref.read(aiVarBypassProvider.notifier), v),
        ),
      ],
    );
  }
}

Future<void> _save(SettingNotifier<bool> notifier, bool value) async {
  try {
    await notifier.set(value);
  } on Object catch (e, st) {
    // The settings store reports a failing write on the page banner.
    _log.warning('saving a tool switch failed', e, st);
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.x4, KSpace.x3, KSpace.x4, 2),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One group's row. [locked] dims the switch and says why (listening stats
/// while the history is not recorded).
class _ToolRow extends ConsumerWidget {
  const _ToolRow({required this.group, this.locked = false});

  final AiToolGroup group;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = aiToolGroupProvider(group);
    final (:icon, :title, :desc) = _texts(l10n, group);
    return KSwitchRow(
      leading: Icon(icon),
      title: Text(title),
      subtitle: locked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (desc != null) Text(desc),
                Text(l10n.aiSetToolsStatsLocked),
              ],
            )
          : (desc == null ? null : Text(desc)),
      switchLabel: title,
      lockedLabel: locked ? l10n.aiSetToolsStatsLocked : null,
      value: ref.watch(provider),
      onChanged: locked ? null : (v) => _save(ref.read(provider.notifier), v),
    );
  }
}

typedef _ToolTexts = ({IconData icon, String title, String? desc});

/// Title, icon and the line under it for each group (what it reads or does,
/// and the variables it fills).
_ToolTexts _texts(AppLocalizations l10n, AiToolGroup group) {
  String vars(Iterable<AiVariable> v) => v.map(variableToken).join(', ');
  return switch (group) {
    AiToolGroup.nowPlaying => (
      icon: KIcons.songs,
      title: l10n.aiSetToolNowPlaying,
      desc: l10n.aiSetToolNowPlayingDesc(
        vars([
          AiVariable.nowPlaying,
          AiVariable.title,
          AiVariable.artist,
          AiVariable.album,
        ]),
      ),
    ),
    AiToolGroup.queue => (
      icon: KIcons.queueMusic,
      title: l10n.aiSetToolQueue,
      desc: l10n.aiSetToolQueueDesc(vars([AiVariable.queue])),
    ),
    AiToolGroup.librarySearch => (
      icon: KIcons.search,
      title: l10n.aiSetToolLibrarySearch,
      desc: l10n.aiSetToolLibrarySearchDesc,
    ),
    AiToolGroup.lyrics => (
      icon: KIcons.lyrics,
      title: l10n.aiSetToolLyrics,
      desc: l10n.aiSetToolLyricsDesc(vars([AiVariable.lyrics])),
    ),
    AiToolGroup.trackInfo => (
      icon: KIcons.info,
      title: l10n.aiSetToolTrackInfo,
      desc: l10n.aiSetToolTrackInfoDesc,
    ),
    AiToolGroup.listeningStats => (
      icon: KIcons.mostPlayed,
      title: l10n.aiSetToolListeningStats,
      desc: l10n.aiSetToolListeningStatsDesc,
    ),
    AiToolGroup.playlists => (
      icon: KIcons.playlists,
      title: l10n.aiSetToolPlaylists,
      desc: l10n.aiSetToolPlaylistsDesc,
    ),
    AiToolGroup.playControl => (
      icon: KIcons.playCircle,
      title: l10n.aiSetToolPlayControl,
      desc: l10n.aiSetToolPlayControlDesc,
    ),
    AiToolGroup.queueEdit => (
      icon: KIcons.queueMusic,
      title: l10n.aiSetToolQueueEdit,
      desc: l10n.aiSetToolQueueEditDesc,
    ),
    AiToolGroup.playlistCreate => (
      icon: KIcons.playlistAdd,
      title: l10n.aiSetToolPlaylistCreate,
      desc: null,
    ),
    AiToolGroup.playlistEdit => (
      icon: KIcons.edit,
      title: l10n.aiSetToolPlaylistEdit,
      desc: l10n.aiSetToolPlaylistEditDesc,
    ),
  };
}
