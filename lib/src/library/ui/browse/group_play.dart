import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
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

/// Plays a whole genre in the order of its page (▶ on a row).
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
);

/// Plays a whole language in the order of its page (▶ on a row).
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
);
