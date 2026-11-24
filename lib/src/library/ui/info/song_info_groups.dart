import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/info/song_details.dart';
import 'song_info_other_rows.dart';
import 'song_info_tag_rows.dart';
import 'song_info_spec.dart';

/// The groups of the song info page for [details], without widgets.
///
/// An empty field is left out unless [showEmpty]. Rows that are not data
/// (Description when empty, Codec when it says what the format already
/// says) never appear as empty fields; "soon" rows always show. [now] gives
/// "N years ago"; [canReveal] adds "open in file manager" to the path;
/// [desktop] picks the longer music-folder text.
List<InfoGroupSpec> buildSongInfoGroups(
  AppLocalizations l10n,
  SongDetails d,
  DateTime now, {
  required bool showEmpty,
  required bool canReveal,
  required bool desktop,
}) {
  final groups = [
    InfoGroupSpec(
      'tags',
      l10n.libraryInfoGroupTags,
      KIcons.tag,
      tagRows(l10n, d, now),
    ),
    InfoGroupSpec(
      'audio',
      l10n.libraryInfoGroupAudio,
      KIcons.volume,
      audioRows(l10n, d),
    ),
    InfoGroupSpec(
      'file',
      l10n.libraryInfoGroupFile,
      KIcons.musicFile,
      fileRows(l10n, d, canReveal, desktop),
    ),
    InfoGroupSpec(
      'you',
      l10n.libraryInfoGroupYou,
      KIcons.artists,
      yourRows(l10n, d),
    ),
  ];
  return [
    for (final g in groups)
      InfoGroupSpec(g.id, g.title, g.icon, [
        for (final r in g.rows)
          if (!r.empty || showEmpty) r,
      ]),
  ];
}

/// How many empty fields the eye would show.
int songInfoEmptyCount(
  AppLocalizations l10n,
  SongDetails d,
  DateTime now, {
  required bool desktop,
}) => [
  for (final g in buildSongInfoGroups(
    l10n,
    d,
    now,
    showEmpty: true,
    canReveal: false,
    desktop: desktop,
  ))
    ...g.rows.where((r) => r.empty),
].length;
