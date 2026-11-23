import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics_status.dart';
import '../state/lyrics_settings.dart';
import 'online/online_labels.dart';
import 'lyrics_spinner.dart';

/// The status line of "Lời cho bài này" for a track with no lyrics to show:
/// what the search is doing or why it found nothing ("Không có lời trên máy ·
/// đang tìm ở 2 nguồn đang bật"). Null when the track shows lyrics, is off,
/// or the lyrics are still loading, and for an instrumental song (its row
/// says it).
class LyricsStatusLine extends StatelessWidget {
  const LyricsStatusLine._({required this.text, this.icon, this.action});

  /// The line for [lyrics], or null when there is nothing to say.
  static Widget? of(BuildContext context, WidgetRef ref, TrackLyrics lyrics) {
    final l10n = AppLocalizations.of(context);
    final (String text, IconData? icon)? line = switch (lyrics) {
      LyricsSearching(:final sourceCount) => (
        l10n.lyricsStatusSearching(sourceCount),
        null,
      ),
      LyricsLookupFailed(:final reason, :final retryAt) => (
        retryAt == null
            ? l10n.lyricsStatusFailed(failReasonShort(l10n, reason))
            : l10n.lyricsStatusFailedRetry(
                failReasonShort(l10n, reason),
                formatClock(context, retryAt),
              ),
        // KIcons names the error circle `offline` and the clock
        // `comingSoon`; the glyphs are what these two states need.
        KIcons.offline,
      ),
      LyricsLookupPaused(:final until) => (
        l10n.lyricsStatusPaused(formatClock(context, until)),
        KIcons.comingSoon,
      ),
      LyricsNotFound(:final asked) => (
        asked == 0 ? l10n.lyricsStatusAllOff : l10n.lyricsStatusNotFound(asked),
        KIcons.lyrics,
      ),
      LyricsNoSource() => (l10n.lyricsStatusNoSource, KIcons.lyrics),
      LyricsNone(reason: LyricsNoneReason.autoOff) => (
        l10n.lyricsStatusAutoOff,
        KIcons.lyrics,
      ),
      LyricsNone() || LyricsUnavailable() || LyricsOff(available: null) => (
        l10n.lyricsModalNoneOnDevice,
        KIcons.lyrics,
      ),
      LyricsOff() ||
      LyricsLoading() ||
      LyricsShown() ||
      LyricsInstrumental() => null,
    };
    if (line == null) return null;
    // With the automatic search off, one tap turns it on (a feature switch).
    final enable =
        lyrics is LyricsNone && lyrics.reason == LyricsNoneReason.autoOff;
    return LyricsStatusLine._(
      text: line.$1,
      icon: line.$2,
      action: enable
          ? TextButton(
              onPressed: () =>
                  ref.read(lyricsAutoSearchProvider.notifier).set(true),
              child: Text(l10n.lyricsStatusEnableAuto),
            )
          : null,
    );
  }

  final String text;

  /// Null draws the spinner of a running search.
  final IconData? icon;

  /// A text button at the end of the line.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(KSpace.x4, 0, KSpace.x4, KSpace.x2),
        padding: const EdgeInsets.all(KSpace.x3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: KRadius.md,
        ),
        child: Row(
          spacing: KSpace.x3,
          children: [
            icon == null
                ? LyricsSpinner(
                    size: KIconSize.sm,
                    color: scheme.onSurfaceVariant,
                    label: AppLocalizations.of(context).lyricsSearchingTitle,
                  )
                : Icon(
                    icon,
                    size: KIconSize.sm,
                    color: scheme.onSurfaceVariant,
                  ),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (action != null) Flexible(child: action!),
          ],
        ),
      ),
    );
  }
}
