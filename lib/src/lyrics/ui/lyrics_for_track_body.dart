import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../../playback/state/now_playing_panel.dart';
import '../domain/lyrics_status.dart';
import '../state/track_lyrics_providers.dart';
import 'lyrics_choice_rows.dart';
import 'lyrics_settings_link.dart';

/// The content of "Lời cho bài này": header with a close button, a status
/// line when the file has no lyrics, the two choice rows, then the online
/// features that are not built yet (dimmed, inert, "Sắp có"). [close] is the
/// modal's guarded close.
class LyricsForTrackBody extends ConsumerWidget {
  const LyricsForTrackBody({
    super.key,
    required this.trackId,
    required this.close,
  });

  final TrackId trackId;
  final bool Function() close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lyrics = ref.watch(trackLyricsProvider(trackId));
    final fileHasNone =
        lyrics.isEmpty ||
        lyrics is LyricsUnavailable ||
        (lyrics is LyricsOff && lyrics.available == null);
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
                if (fileHasNone) const _StatusLine(),
                LyricsChoiceRows(trackId: trackId, close: close),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: KSpace.x2),
                  child: Divider(height: 1),
                ),
                // KListRow has no plain variant yet and fills with
                // surfaceContainerLow, which shows as a box on the dialog
                // surface; these inert rows must read as plain rows.
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme
                        .copyWith(surfaceContainerLow: Colors.transparent),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SoonRow(
                        icon: KIcons.online,
                        title: l10n.lyricsFindOnline,
                      ),
                      _SoonRow(
                        icon: KIcons.ai,
                        title: l10n.lyricsFromAudio,
                        subtitle: l10n.lyricsFromAudioSub,
                      ),
                      _SoonRow(
                        icon: KIcons.fileExport,
                        title: l10n.lyricsSaveLyrics,
                      ),
                    ],
                  ),
                ),
                const KGap(KSpace.x2),
              ],
            ),
          ),
        ),
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
    router.go(lyricsSettingsLocation);
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

/// "Không có lời trên máy" in a `surfaceContainerHighest` box.
class _StatusLine extends StatelessWidget {
  const _StatusLine();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(KSpace.x4, 0, KSpace.x4, KSpace.x2),
      padding: const EdgeInsets.all(KSpace.x3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: KRadius.md,
      ),
      child: Row(
        spacing: KSpace.x3,
        children: [
          Icon(
            KIcons.lyrics,
            size: KIconSize.sm,
            color: scheme.onSurfaceVariant,
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context).lyricsModalNoneOnDevice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// A feature that is not built yet: dimmed, never tappable, with its marker.
class _SoonRow extends StatelessWidget {
  const _SoonRow({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return KListRow(
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Text(
        AppLocalizations.of(context).appComingSoon,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
