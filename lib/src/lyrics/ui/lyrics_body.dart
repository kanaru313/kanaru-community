import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import '../domain/lyrics_status.dart';
import '../state/lyrics_settings.dart';
import '../state/playing_lyrics_providers.dart';
import 'lyrics_state_view.dart';
import 'online/open_lyrics_plugin_store.dart';
import 'online/open_online_targets.dart';
import 'plain_lyrics_view.dart';
import 'synced_lyrics_view.dart';

/// The lyrics area of the playing track on the mobile lyrics screen or the
/// desktop tab: picks the synced view, the plain view or a state view from
/// the track's lyrics, and sizes them through [KLyricsMetricsBuilder] and the
/// user's font scale, alignment, dim level and auto-return.
///
/// Loading is blank (never the previous track's lines). Every other state
/// without lyrics is a [LyricsStateView]; its "find online" buttons open
/// `openFindOnline`, "add a source" the lyrics plugin store. The synced view is
/// keyed by the entry and its lyrics, so a new track builds a fresh view and
/// the same lyrics keep their scroll.
class LyricsBody extends ConsumerWidget {
  const LyricsBody({
    super.key,
    required this.surface,
    this.coverColumnShown = true,
    this.onOpenChoice,
  }) : assert(surface != KLyricsSurface.card, 'the card has its own widget');

  final KLyricsSurface surface;

  /// Desktop tab: whether the cover column is shown beside the lyrics.
  final bool coverColumnShown;

  /// Wired to the off state's button by the lyrics source owner; null hides
  /// the button.
  final VoidCallback? onOpenChoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playingLyricsProvider);
    final fontScale = ref.watch(lyricsFontScaleProvider).factor;
    final align = ref.watch(lyricsAlignProvider);
    final dim = ref.watch(lyricsDimProvider);
    final autoReturn = ref.watch(lyricsAutoReturnProvider);
    final desktop = surface == KLyricsSurface.tab;
    final trackId = playing.trackId;
    return switch (playing.lyrics) {
      LyricsLoading() => const SizedBox.expand(),
      LyricsShown(:final lyrics) => KLyricsMetricsBuilder(
        surface: surface,
        coverColumnShown: coverColumnShown,
        builder: (context, metrics) =>
            _shown(playing, lyrics, metrics, fontScale, align, dim, autoReturn),
      ),
      // The state view switches over every state itself, so a new state is a
      // compile error there, not a silent blank here.
      final state => LyricsStateView(
        lyrics: state,
        desktop: desktop,
        onOpenChoice: onOpenChoice,
        onFindOnline: trackId == null
            ? null
            : () => openFindOnline(context, trackId),
        onAddSource: () => openLyricsPluginStore(context, ref),
      ),
    };
  }

  Widget _shown(
    PlayingLyrics playing,
    Lyrics lyrics,
    KLyricsMetrics metrics,
    double fontScale,
    LyricsAlign align,
    LyricsDim dim,
    LyricsAutoReturn autoReturn,
  ) {
    final size = metrics.lineSize * fontScale;
    if (!lyrics.synced) {
      return PlainLyricsView(
        key: ValueKey((playing.entryId, lyrics)),
        lyrics: lyrics,
        lineSize: size,
        sidePadding: metrics.sidePadding,
        align: align,
      );
    }
    return SyncedLyricsView(
      key: ValueKey((playing.entryId, lyrics)),
      lyrics: lyrics,
      lineSize: size,
      sidePadding: metrics.sidePadding,
      viewportHeight: metrics.viewportHeight,
      dim: dim,
      align: align,
      autoReturn: autoReturn,
    );
  }
}
