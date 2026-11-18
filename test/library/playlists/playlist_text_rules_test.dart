import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/row_uids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_text_rules.dart';

void main() {
  test('favorites uid equals the database uid', () {
    expect(PlaylistUids.favorites, favoritesPlaylistUid);
  });

  test('graphemeLength counts clusters', () {
    expect(graphemeLength('👨‍👩‍👧‍👦'), 1);
    expect(graphemeLength('é'), 1);
    expect(graphemeLength('abc'), 3);
  });

  test('name drops controls and trims; description keeps line breaks', () {
    expect(cleanPlaylistName('  a\u0000b\nc\u007F  '), 'abc');
    expect(cleanPlaylistDescription(' a\nb\tc\u0000 '), 'a\nb\tc');
  });

  test('name boundary is 200 graphemes on the cleaned value', () {
    expect(checkPlaylistName('a' * 200), isNull);
    expect(checkPlaylistName('a' * 201), PlaylistNameProblem.tooLong);
    expect(checkPlaylistName('👨‍👩‍👧‍👦' * 200), isNull);
    expect(checkPlaylistName(' \u0001 '), PlaylistNameProblem.empty);
    expect(checkPlaylistName('${'a' * 200}\u0000'), isNull);
  });

  test('description boundary is 2000 graphemes', () {
    expect(isPlaylistDescriptionTooLong('a' * 2000), isFalse);
    expect(isPlaylistDescriptionTooLong('a' * 2001), isTrue);
  });

  test('capPlaylistName keeps a trailing suffix', () {
    final capped = capPlaylistName('${'a' * 199} (bản sao)');
    expect(graphemeLength(capped), playlistNameMaxLength);
    expect(capped.endsWith(' (bản sao)'), isTrue);
    expect(capPlaylistName('short'), 'short');
    expect(graphemeLength(capPlaylistName('b' * 300)), playlistNameMaxLength);
  });
}
