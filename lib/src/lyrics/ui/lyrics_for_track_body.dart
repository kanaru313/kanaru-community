import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../../playback/state/now_playing_panel.dart';
import '../state/online/online_lookup_providers.dart';
import '../state/track_lyrics_providers.dart';
import 'lyrics_choice_rows.dart';
import 'lyrics_find_rows.dart';
import 'lyrics_online_bar.dart';
import 'lyrics_settings_link.dart';
import 'lyrics_status_line.dart';
import 'online/online_row_info.dart';

/// The content of "Lời cho bài này": header with a close button, a status line
/// when the track has no lyrics to show, the choice rows (file, online copy,
/// none), the online and not-yet-built features, and, when there is something
/// to do with the online copy that shows, the bar to keep or refuse it.
/// [close] is the modal's guarded close; [onFindOnline] is what the "Tìm lời
/// trực tuyến…" row opens (null leaves it dimmed until the search exists).
class LyricsForTrackBody extends ConsumerWidget {
  const LyricsForTrackBody({
    super.key,
    required this.trackId,
    required this.close,
    this.onFindOnline,
  });

  final TrackId trackId;
  final bool Function() close;
  final VoidCallback? onFindOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyrics = ref.watch(trackLyricsProvider(trackId));
    final pin = ref.watch(lyricsPinProvider(trackId)).value;
    final online = onlineRowInfoOf(lyrics, pin);
    final status = LyricsStatusLine.of(context, ref, lyrics);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(onClose: close),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?status,
                LyricsChoiceRows(
                  trackId: trackId,
                  close: close,
                  online: online,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: KSpace.x2),
                  child: Divider(height: 1),
                ),
                LyricsFindRows(close: close, onFindOnline: onFindOnline),
                const KGap(KSpace.x2),
              ],
            ),
          ),
        ),
        LyricsOnlineBar(trackId: trackId, info: online, close: close),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onClose});

  final bool Function() onClose;

  /// Closes the modal and the desktop Now Playing panel, then opens Settings ›
  /// Lyrics. Everything is taken before closing: the modal's context is gone
  /// once it pops.
  void _openSettings(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final panel = ref.read(nowPlayingPanelProvider.notifier);
    if (!onClose()) return;
    panel.close();
    router.go(lyricsSourcesSettingsLocation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x2,
        KSpace.x2,
        KSpace.x2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.lyricsForTrackTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          KIconButton(
            icon: KIcons.settings,
            tooltip: l10n.lyricsSettingsModalSettings,
            padding: const EdgeInsets.all(KSpace.x3),
            onPressed: () => _openSettings(context, ref),
          ),
          KIconButton(
            icon: KIcons.close,
            tooltip: l10n.lyricsModalClose,
            padding: const EdgeInsets.all(KSpace.x3),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
