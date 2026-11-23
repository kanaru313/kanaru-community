import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics_status.dart';
import 'lyrics_searching_view.dart';
import 'online/online_labels.dart';

/// The lyrics area of a track that shows no lyrics: an icon (a spinner while
/// searching), a title, one sentence and, where there is something to do, a
/// button. [lyrics] is the track's state; [desktop] picks the sentence of the
/// desktop tab (right-click) or of the mobile screen for "off".
///
/// A button shows only when the owner gives its callback: [onOpenChoice]
/// ("Lời cho bài này", off state), [onFindOnline] ("Tìm lời trực tuyến…",
/// "Tìm thủ công…") and [onAddSource] ("Thêm nguồn lời trực tuyến"). Loading
/// stays blank; lyrics to show are not this widget's business.
class LyricsStateView extends StatelessWidget {
  const LyricsStateView({
    super.key,
    required this.lyrics,
    required this.desktop,
    this.onOpenChoice,
    this.onFindOnline,
    this.onAddSource,
  });

  final TrackLyrics lyrics;
  final bool desktop;
  final VoidCallback? onOpenChoice;
  final VoidCallback? onFindOnline;
  final VoidCallback? onAddSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (lyrics) {
      LyricsLoading() || LyricsShown() => const SizedBox.expand(),
      LyricsSearching(:final sourceCount) => LyricsSearchingView(
        title: l10n.lyricsSearchingTitle,
        message: l10n.lyricsSearchingMessage(sourceCount),
      ),
      // The file has none and the automatic search is off: a manual search.
      LyricsNone(reason: LyricsNoneReason.autoOff) => KEmpty(
        icon: KIcons.lyrics,
        title: l10n.lyricsNoneTitle,
        message: l10n.lyricsNoneAutoOffMessage,
        action: _button(
          onFindOnline,
          l10n.lyricsFindManually,
          icon: KIcons.online,
        ),
      ),
      // A song without enough tags to search by, or not the playing one, and
      // a track without a file: nothing to offer.
      LyricsNone() || LyricsUnavailable() => KEmpty(
        icon: KIcons.lyrics,
        title: l10n.lyricsNoneTitle,
        message: l10n.lyricsNoneMessage,
      ),
      LyricsNotFound(:final asked, :final off) => KEmpty(
        icon: KIcons.search,
        title: l10n.lyricsNotFoundTitle,
        message: switch ((asked, off)) {
          (0, _) => l10n.lyricsNotFoundAllOff,
          (_, 0) => l10n.lyricsNotFoundAsked(asked),
          _ =>
            '${l10n.lyricsNotFoundAsked(asked)} ${l10n.lyricsNotFoundOff(off)}',
        },
        action: _button(
          onFindOnline,
          l10n.lyricsFindOnline,
          icon: KIcons.online,
        ),
      ),
      LyricsNoSource() => KEmpty(
        icon: KIcons.lyrics,
        title: l10n.lyricsNoneTitle,
        message: l10n.lyricsNoSourceMessage,
        action: _button(
          onAddSource,
          l10n.lyricsAddSource,
          icon: KIcons.extension,
        ),
      ),
      LyricsInstrumental() => KEmpty(
        icon: KIcons.songs,
        title: l10n.lyricsInstrumentalTitle,
        message: l10n.lyricsInstrumentalMessage,
        action: onFindOnline == null
            ? null
            : OutlinedButton(
                onPressed: onFindOnline,
                child: Text(l10n.lyricsInstrumentalFindOnline),
              ),
      ),
      // The glyph names the error; KIcons has no error / clock names of its
      // own for these two states yet (`offline` is the error circle,
      // `comingSoon` the clock).
      LyricsLookupFailed(:final reason, :final asked, :final retryAt) => KEmpty(
        icon: KIcons.offline,
        title: l10n.lyricsFailedTitle,
        message: failedAreaMessage(context, reason, asked, retryAt),
        action: _button(
          onFindOnline,
          l10n.lyricsFindOnline,
          icon: KIcons.online,
        ),
      ),
      LyricsLookupPaused(:final until) => KEmpty(
        icon: KIcons.comingSoon,
        title: l10n.lyricsPausedTitle,
        message: l10n.lyricsPausedMessage(formatClock(context, until)),
        action: _button(
          onFindOnline,
          l10n.lyricsFindOnline,
          icon: KIcons.online,
        ),
      ),
      LyricsOff() => KEmpty(
        icon: KIcons.lyricsOff,
        title: l10n.lyricsOffTitle,
        message: desktop
            ? l10n.lyricsOffMessageDesktop
            : l10n.lyricsOffMessageMobile,
        action: onOpenChoice == null
            ? null
            : FilledButton.tonal(
                onPressed: onOpenChoice,
                child: Text(l10n.lyricsOffOpenChoice),
              ),
      ),
    };
  }

  /// A tonal button with an icon, or nothing without a callback.
  Widget? _button(VoidCallback? onPressed, String label, {IconData? icon}) =>
      onPressed == null
      ? null
      : FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: icon == null ? null : Icon(icon),
          label: Text(label),
        );
}
