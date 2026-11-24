import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/info/song_details.dart';
import 'song_info_formats.dart';

/// The one notice above the groups; the order is the priority.
enum SongInfoNoticeKind { fileMissing, scanError, fewTags }

/// Which notice [d] gets, if any: a missing file beats a tag read error,
/// which beats a file with almost no tags (no artist, album, genre or year
/// and a title equal to the file name without its extension).
SongInfoNoticeKind? songInfoNoticeKind(SongDetails d) {
  if (d.status == SongFileStatus.missing) return SongInfoNoticeKind.fileMissing;
  final error = d.scanError;
  if (error != null && error.trim().isNotEmpty) {
    return SongInfoNoticeKind.scanError;
  }
  final path = d.path;
  final bare =
      d.artists.isEmpty &&
      (d.album ?? '').trim().isEmpty &&
      (d.genre ?? '').trim().isEmpty &&
      d.year == null;
  if (bare && path != null && d.title == fileStem(path)) {
    return SongInfoNoticeKind.fewTags;
  }
  return null;
}

/// [songInfoNoticeKind] drawn as a `KInlineNotice` (no button: tags are
/// edited from the song menu).
class SongInfoNotice extends StatelessWidget {
  const SongInfoNotice({super.key, required this.details});

  final SongDetails details;

  @override
  Widget build(BuildContext context) {
    final kind = songInfoNoticeKind(details);
    if (kind == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final since = details.missingSince;
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x3),
      child: switch (kind) {
        SongInfoNoticeKind.fileMissing => KInlineNotice(
          icon: KIcons.noMedia,
          tone: KInlineNoticeTone.error,
          title: l10n.libraryInfoMissingTitle,
          message: since == null
              ? l10n.libraryInfoMissingBodyNoDate
              : l10n.libraryInfoMissingBody(
                  formatInfoDate(since, l10n.localeName),
                ),
        ),
        SongInfoNoticeKind.scanError => KInlineNotice(
          icon: KIcons.warning,
          tone: KInlineNoticeTone.error,
          title: l10n.libraryInfoScanErrorTitle,
          message: l10n.libraryInfoScanErrorBody,
        ),
        SongInfoNoticeKind.fewTags => KInlineNotice(
          icon: KIcons.info,
          title: l10n.libraryInfoTaglessTitle,
          message: l10n.libraryInfoTaglessBody,
        ),
      },
    );
  }
}
