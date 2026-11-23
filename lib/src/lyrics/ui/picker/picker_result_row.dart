import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../lyrics_plain_rows.dart';
import '../online/plugin_avatar.dart';
import 'picker_result_detail.dart';

/// One search result of the picker: the source's picture, the title with its
/// kind label ("Đồng bộ" / "Thường", and "Nguồn đang tắt" for a source asked
/// on request) and the detail line "4:12 khớp · artist · album" (the length
/// first, so a long artist or album never cuts the difference).
///
/// On the desktop list it is a single-choice row ([selected] shows the tint);
/// on the touch shells it is a plain row with a `›` that opens the preview
/// page, where nothing is chosen.
class PickerResultRow extends StatelessWidget {
  const PickerResultRow({
    super.key,
    required this.candidate,
    required this.sourceName,
    required this.sourceOff,
    required this.songDuration,
    required this.selected,
    required this.onTap,
  });

  final LyricsCandidate candidate;
  final String sourceName;

  /// The source is switched off and was asked on request.
  final bool sourceOff;
  final Duration? songDuration;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = PluginAvatar(
      providerId: candidate.providerId,
      name: sourceName,
      size: KIconSize.md,
    );
    final title = _Title(
      title: candidate.title,
      synced: candidate.body?.syncedLrc != null,
      known: candidate.body != null,
      off: sourceOff,
    );
    final detail = PickerResultDetail(
      candidate: candidate,
      songDuration: songDuration,
    );
    if (FormFactor.of(context) == FormFactor.desktop) {
      return SelectionRow(
        leading: avatar,
        title: title,
        subtitle: detail,
        selected: selected,
        onTap: onTap,
      );
    }
    return LyricsPlainRows(
      child: KListRow(
        leading: avatar,
        title: title,
        subtitle: detail,
        trailing: Icon(
          KIcons.chevronRight,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.title,
    required this.synced,
    required this.known,
    required this.off,
  });

  final String title;
  final bool synced;

  /// The search answered with the lyrics, so the kind is known; a result of a
  /// two-step source shows none until its lyrics are fetched.
  final bool known;
  final bool off;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: KSpace.x2,
      runSpacing: KSpace.x1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title),
        if (known)
          KChip.tag(
            tone: synced ? KTagTone.highlight : KTagTone.muted,
            label: Text(synced ? l10n.lyricsKindSynced : l10n.lyricsKindPlain),
          ),
        if (off)
          KChip.tag(
            tone: KTagTone.problem,
            label: Text(l10n.lyricsPickerBadgeOff),
          ),
      ],
    );
  }
}
