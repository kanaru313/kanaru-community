import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/list_prefs_providers.dart';
import 'play_actions.dart';

/// Play context of a genre: the same one the detail page's Play button, the
/// menu's Play and the row's ▶ use. [ref] is the encoded stored key.
PlayContext genrePlayContext(String genreKey, String label) =>
    PlayContext(PlayContextKind.genre, ref: encodeKey(genreKey), label: label);

/// Play context of a language; the group without a language (null [code])
/// uses the `_unknown` id of its location.
PlayContext languagePlayContext(String? code, String label) => PlayContext(
  PlayContextKind.language,
  ref: code == null ? '_unknown' : encodeKey(code),
  label: label,
);

/// Key of a genre's detail page in the sort preferences (`genre:<id>`).
String genreDetailItem(String genreKey) => 'genre:${encodeKey(genreKey)}';

/// Key of a language's detail page in the sort preferences.
String languageDetailItem(String? code) =>
    'language:${code == null ? '_unknown' : encodeKey(code)}';

/// Plays a whole genre in the sort of its page: its own choice, else the remembered default
/// of the detail lists (▶ on a row).
Future<void> playGenre(
  WidgetRef ref,
  BuildContext context,
  String genreKey,
  String label,
) => playScope(
  ref,
  context,
  SongScope.genre(genreKey),
  BrowseList.detailSongs,
  genrePlayContext(genreKey, label),
  sort: ref.read(
    detailSortProvider((
      list: BrowseList.detailSongs,
      item: genreDetailItem(genreKey),
    )),
  ),
);

/// Plays a whole language in the sort of its page (▶ on a row).
Future<void> playLanguage(
  WidgetRef ref,
  BuildContext context,
  String? code,
  String label,
) => playScope(
  ref,
  context,
  SongScope.language(code),
  BrowseList.detailSongs,
  languagePlayContext(code, label),
  sort: ref.read(
    detailSortProvider((
      list: BrowseList.detailSongs,
      item: languageDetailItem(code),
    )),
  ),
);
