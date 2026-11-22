import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

/// The two states of the lyrics area that say something (loading stays
/// blank).
enum LyricsStateKind {
  /// No lyrics in the file or beside it, or the track has no local file.
  none,

  /// The user turned lyrics off for this song.
  off,
}

/// The lyrics area without lyrics: an icon, a title, one sentence and, for
/// "off", a button that opens the song's lyrics choice when the owner gives
/// one. [desktop] picks the sentence of the desktop tab (right-click) or of
/// the mobile screen.
class LyricsStateView extends StatelessWidget {
  const LyricsStateView({
    super.key,
    required this.kind,
    required this.desktop,
    this.onOpenChoice,
  });

  final LyricsStateKind kind;
  final bool desktop;

  /// The "Lời cho bài này" button of the off state; null hides it.
  final VoidCallback? onOpenChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (kind) {
      LyricsStateKind.none => KEmpty(
        icon: KIcons.lyrics,
        title: l10n.lyricsNoneTitle,
        message: l10n.lyricsNoneMessage,
      ),
      LyricsStateKind.off => KEmpty(
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
}
