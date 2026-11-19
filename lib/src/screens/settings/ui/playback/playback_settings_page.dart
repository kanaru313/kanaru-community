import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/domain/playback_settings.dart';
import '../../../../playback/state/playback_settings_providers.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import '../soon_row.dart';
import 'listen_rule_sheet.dart';

/// Playback: the previous button and the listening history are live; the
/// sound rows are "coming soon" until the engine supports them.
class PlaybackSettingsPage extends ConsumerStatefulWidget {
  const PlaybackSettingsPage({super.key});

  @override
  ConsumerState<PlaybackSettingsPage> createState() =>
      _PlaybackSettingsPageState();
}

class _PlaybackSettingsPageState extends ConsumerState<PlaybackSettingsPage> {
  final _previousKey = GlobalKey();
  final _listenKey = GlobalKey();

  Future<void> _pickPrevious(
    AppLocalizations l10n,
    PreviousButtonPolicy current,
  ) async {
    final notifier = ref.read(previousButtonProvider.notifier);
    final chosen = await showSelectionPicker<PreviousButtonPolicy>(
      context,
      anchor: _previousKey,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.settingsPlaybackPreviousButton),
      selected: current,
      options: [
        SelectionOption(
          value: PreviousButtonPolicy.alwaysPrevious,
          title: Text(l10n.settingsPlaybackPreviousAlways),
          subtitle: Text(l10n.settingsPlaybackPreviousAlwaysDesc),
        ),
        SelectionOption(
          value: PreviousButtonPolicy.restartAfter3s,
          title: Text(l10n.settingsPlaybackPreviousRestart),
          subtitle: Text(l10n.settingsPlaybackPreviousRestartDesc),
        ),
      ],
    );
    if (chosen != null) await notifier.set(chosen);
  }

  Future<void> _openListenRule(AppLocalizations l10n) {
    // Taken before the sheet opens: it may outlive this page.
    final container = ProviderScope.containerOf(context);
    final notifier = container.read(listenRuleProvider.notifier);
    return showListenRuleSheet(
      context,
      l10n: l10n,
      anchor: _listenKey,
      initial: container.read(listenRuleProvider),
      current: () => container.read(listenRuleProvider),
      save: notifier.set,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final previous = ref.watch(previousButtonProvider);
    final history = ref.watch(historyEnabledProvider);
    final rule = ref.watch(listenRuleProvider);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    return SettingsScaffold(
      title: l10n.settingsRootPlayback,
      parentPath: SettingsPaths.root,
      children: [
        SetupSection(
          title: Text(l10n.settingsPlaybackBlockPlay),
          children: [
            SoonRow(
              icon: KIcons.gapless,
              title: Text(l10n.settingsPlaybackGapless),
              desc: l10n.settingsPlaybackGaplessDesc,
            ),
            SoonRow(
              icon: KIcons.fadeIn,
              title: Text(l10n.settingsPlaybackFadeIn),
              desc: l10n.settingsPlaybackOff,
            ),
            SoonRow(
              icon: KIcons.fadeOut,
              title: Text(l10n.settingsPlaybackFadeOut),
              desc: l10n.settingsPlaybackOff,
            ),
            SetupValueRow(
              anchorKey: _previousKey,
              icon: KIcons.previousButton,
              title: Text(l10n.settingsPlaybackPreviousButton),
              value: Text(switch (previous) {
                PreviousButtonPolicy.alwaysPrevious =>
                  l10n.settingsPlaybackPreviousAlways,
                PreviousButtonPolicy.restartAfter3s =>
                  l10n.settingsPlaybackPreviousRestart,
              }),
              onTap: () => _pickPrevious(l10n, previous),
            ),
            SoonRow(
              icon: KIcons.crossfade,
              title: Text(l10n.settingsPlaybackCrossfade),
              desc: l10n.settingsPlaybackCrossfadeDesc,
            ),
          ],
        ),
        SetupSection(
          title: Text(l10n.settingsPlaybackBlockSound),
          children: [
            if (desktop)
              SoonRow(
                icon: KIcons.outputDevice,
                title: Text(l10n.settingsPlaybackOutputDevice),
                desc: l10n.settingsPlaybackAuto,
              ),
            SoonRow(
              icon: KIcons.replayGain,
              title: Text(l10n.settingsPlaybackReplayGain),
              desc: l10n.settingsPlaybackOff,
            ),
            SoonRow(
              icon: KIcons.preamp,
              title: Text(l10n.settingsPlaybackPreamp),
              desc:
                  '${l10n.settingsPlaybackPreampValue(0)}\n'
                  '${l10n.settingsPlaybackNeedsReplayGain}',
            ),
            SoonRow(
              icon: KIcons.clipping,
              title: Text(l10n.settingsPlaybackClipping),
              desc:
                  '${l10n.settingsPlaybackClippingDesc}\n'
                  '${l10n.settingsPlaybackNeedsReplayGain}',
            ),
          ],
        ),
        SetupSection(
          title: Text(l10n.settingsPlaybackBlockHistory),
          children: [
            KSwitchRow(
              leading: const Icon(KIcons.history),
              title: Text(l10n.settingsPlaybackHistory),
              subtitle: Text(
                history
                    ? l10n.settingsPlaybackHistoryDesc
                    : '${l10n.settingsPlaybackHistoryDesc}\n'
                          '${l10n.settingsPlaybackHistoryOff}',
              ),
              switchLabel: l10n.settingsPlaybackHistory,
              value: history,
              onChanged: (v) =>
                  ref.read(historyEnabledProvider.notifier).set(v),
            ),
            SetupValueRow(
              anchorKey: _listenKey,
              icon: KIcons.count,
              title: Text(l10n.settingsPlaybackListenRule),
              value: Text(listenRuleValue(l10n, rule)),
              enabled: history,
              disabledReason: Text(l10n.settingsPlaybackListenNeedsHistory),
              onTap: () => _openListenRule(l10n),
            ),
          ],
        ),
      ],
    );
  }
}
