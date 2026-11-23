import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics_status.dart';
import '../domain/lyrics_summary.dart';
import '../state/lyrics_choice_commands.dart';
import '../state/playing_lyrics_providers.dart';
import 'lyrics_labels.dart';
import 'online/online_source_of.dart';
import 'online/plugin_avatar.dart';

final _log = Logger('lyrics_source_button');

/// The button that shows where the playing song's lyrics come from and opens
/// "Lời cho bài này" ([onOpen]). Its glyph follows the lyrics: the lyrics icon
/// in primary when the file has some, the plugin's icon for online lyrics (a
/// grey initial when the plugin is removed; on a `surfaceContainerHigh` disc
/// on the desktop shell), a ring while the search runs, dimmed while there
/// are none (or the search failed or is paused) or they load, struck through
/// when the user turned them off. Disabled only without a track: a file that
/// cannot be read keeps the dimmed look of "none" but still opens the modal,
/// like every other entry (the song menu cannot know a file is unreadable
/// without reading it); the modal says the file has no lyrics and still
/// offers "Không hiện lời".
///
/// The button is 48 dp wide on the mobile shell and 40 dp on the desktop
/// shell, where the tooltip also names the `L` key and [onToggle] (right
/// click) turns the song's lyrics off or back on. Only this widget watches
/// the lyrics summary.
class LyricsSourceButton extends ConsumerWidget {
  const LyricsSourceButton({super.key, required this.onOpen, this.onToggle});

  final VoidCallback onOpen;

  /// Right-click on the desktop shell; null leaves the gesture unused.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final playing = ref.watch(playingLyricsProvider);
    final state = playing.lyrics;
    final summary = summaryOf(state);
    final usable = playing.trackId != null;
    final named = lyricsLabelOf(l10n, state);
    final label = named.isEmpty ? l10n.lyricsForTrackTitle : named;
    final tooltip = desktop
        ? [
            l10n.lyricsSourceTooltipDesktop(label),
            if (onToggle != null) l10n.lyricsSourceToggleHint,
          ].join('\n')
        : label;
    final target = desktop ? KLayout.minTargetDesktop : KLayout.minTarget;
    final online = onlineShownOf(state);
    final searching = state is LyricsSearching;
    final Widget? glyph = online != null
        ? _OnlineGlyph(online: online, disc: desktop)
        : searching
        ? _SearchingGlyph(color: scheme.onSurfaceVariant)
        : null;
    final button = KIconButton(
      icon: glyph == null
          ? (summary == LyricsSummary.off ? KIcons.lyricsOff : KIcons.lyrics)
          : null,
      tooltip: tooltip,
      semanticLabel: label,
      color: switch (summary) {
        LyricsSummary.tagSynced ||
        LyricsSummary.tagPlain ||
        LyricsSummary.lrcSynced ||
        LyricsSummary.lrcPlain ||
        LyricsSummary.onlineSynced ||
        LyricsSummary.onlinePlain => scheme.primary,
        LyricsSummary.off || LyricsSummary.searching => null,
        _ => scheme.onSurface.withValues(alpha: 0.38),
      },
      padding: online != null && desktop
          ? EdgeInsets.zero
          : EdgeInsets.all((target - KIconSize.md) / 2),
      onPressed: usable ? onOpen : null,
      child: glyph,
    );
    final toggle = onToggle;
    if (!desktop || toggle == null || !usable) return button;
    return KContextRegion(
      longPressOpens: false,
      onOpen: (_) => toggle(),
      child: button,
    );
  }
}

/// The plugin's icon at 22 dp in the 24 dp icon slot; on the desktop shell
/// the whole 40 dp target is a `surfaceContainerHigh` disc behind it.
class _OnlineGlyph extends StatelessWidget {
  const _OnlineGlyph({required this.online, required this.disc});

  final OnlineShown online;
  final bool disc;

  static const double _icon = 22;

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox.square(
      dimension: KIconSize.md,
      child: Center(
        child: PluginAvatar(
          providerId: online.providerId,
          name: online.providerName,
          size: _icon,
        ),
      ),
    );
    if (!disc) return avatar;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: KLayout.minTargetDesktop,
        child: Center(child: avatar),
      ),
    );
  }
}

/// The lyrics icon with a ring turning around it (a still arc with animations
/// off) while the automatic search runs.
class _SearchingGlyph extends StatelessWidget {
  const _SearchingGlyph({required this.color});

  final Color color;

  static const double _ring = 32;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: KIconSize.md,
      child: OverflowBox(
        maxWidth: _ring,
        maxHeight: _ring,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(KIcons.lyrics, size: KIconSize.md, color: color),
            SizedBox.square(
              dimension: _ring,
              child: ExcludeSemantics(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: still ? 0.3 : null,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A right-click handler for [LyricsSourceButton.onToggle]: turns the playing
/// song's lyrics off, or back to automatic when they are off.
VoidCallback toggleLyricsOfPlaying(WidgetRef ref) => () {
  final playing = ref.read(playingLyricsProvider);
  final id = playing.trackId;
  if (id == null) return;
  final write = ref
      .read(lyricsChoiceCommandsProvider)
      .toggle(id, currentlyOff: playing.lyrics is LyricsOff);
  unawaited(
    write.catchError((Object error, StackTrace stack) {
      _log.warning('lyrics toggle failed', error, stack);
    }),
  );
};
