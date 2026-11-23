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

final _log = Logger('lyrics_source_button');

/// The button that shows where the playing song's lyrics come from and opens
/// "Lời cho bài này" ([onOpen]). Its icon follows the lyrics: primary when
/// the file has some, dimmed while there are none or they load, struck
/// through when the user turned them off. Disabled only without a track: a
/// file that cannot be read keeps the dimmed look of "none" but still opens
/// the modal, like every other entry (the song menu cannot know a file is
/// unreadable without reading it); the modal says the file has no lyrics and
/// still offers "Không hiện lời".
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
    final summary = summaryOf(playing.lyrics);
    final usable = playing.trackId != null;
    final named = lyricsSummaryLabel(l10n, summary);
    final label = named.isEmpty ? l10n.lyricsForTrackTitle : named;
    final tooltip = desktop
        ? [
            l10n.lyricsSourceTooltipDesktop(label),
            if (onToggle != null) l10n.lyricsSourceToggleHint,
          ].join('\n')
        : label;
    final button = KIconButton(
      icon: summary == LyricsSummary.off ? KIcons.lyricsOff : KIcons.lyrics,
      tooltip: tooltip,
      semanticLabel: label,
      color: switch (summary) {
        LyricsSummary.tagSynced ||
        LyricsSummary.tagPlain ||
        LyricsSummary.lrcSynced ||
        LyricsSummary.lrcPlain ||
        LyricsSummary.onlineSynced ||
        LyricsSummary.onlinePlain => scheme.primary,
        LyricsSummary.off => null,
        _ => scheme.onSurface.withValues(alpha: 0.38),
      },
      padding: EdgeInsets.all(
        ((desktop ? KLayout.minTargetDesktop : KLayout.minTarget) -
                KIconSize.md) /
            2,
      ),
      onPressed: usable ? onOpen : null,
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
