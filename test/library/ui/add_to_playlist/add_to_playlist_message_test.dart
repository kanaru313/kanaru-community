import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist_message.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist_model.dart';

import 'support/picker_host.dart';

AddSummary _s({
  bool failed = false,
  int songs = 1,
  int playlists = 1,
  String? name = 'Chill',
  int added = 1,
  int skippedOne = 0,
  int created = 0,
  int skipped = 0,
  int moved = 0,
  int dropped = 0,
  int gone = 0,
  bool nothingNew = false,
}) => AddSummary(
  failed: failed,
  songs: songs,
  playlists: playlists,
  singleName: playlists == 1 ? name : null,
  singleAdded: playlists == 1 ? added : 0,
  singleSkipped: playlists == 1 ? skippedOne : 0,
  created: created,
  skipped: skipped,
  moved: moved,
  dropped: dropped,
  gone: gone,
  nothingNew: nothingNew,
);

void main() {
  final en = l10nOf('en');
  final vi = l10nOf('vi');

  group('english', () {
    String msg(AddSummary s) => addToPlaylistMessage(en, s);

    test('one song into one playlist', () {
      expect(msg(_s()), 'Added 1 song to “Chill”');
    });

    test('several songs into one playlist, some skipped', () {
      expect(
        msg(_s(songs: 3, added: 3, skippedOne: 2, skipped: 2)),
        'Added 3 songs to “Chill”, skipped 2',
      );
    });

    test('several playlists, one of them new', () {
      expect(
        msg(_s(songs: 3, playlists: 3, created: 1)),
        'Added 3 songs to 3 playlists (1 new)',
      );
    });

    test('several playlists, songs skipped', () {
      expect(
        msg(_s(songs: 3, playlists: 2, skipped: 2)),
        'Added 3 songs to 2 playlists, skipped 2',
      );
    });

    test('one new playlist is named', () {
      expect(
        msg(_s(songs: 3, added: 3, name: 'Road trip', created: 1)),
        'Added 3 songs to “Road trip”',
      );
    });

    test('nothing new: one playlist and many', () {
      expect(
        msg(_s(added: 0, nothingNew: true)),
        'Every song is already in “Chill”',
      );
      expect(
        msg(_s(playlists: 3, songs: 0, nothingNew: true)),
        'Every song is already in the 3 playlists',
      );
    });

    test('old copies dropped by moving, one and many targets', () {
      expect(
        msg(_s(songs: 2, added: 2, moved: 1)),
        'Added 2 songs to “Chill”, dropped 1 old copy',
      );
      expect(
        msg(_s(songs: 3, playlists: 2, skipped: 1, moved: 2)),
        'Added 3 songs to 2 playlists, skipped 1, dropped 2 old copies',
      );
    });

    test('songs left out of the library', () {
      expect(
        msg(_s(songs: 2, added: 2, dropped: 1)),
        'Added 2 songs to “Chill”, 1 song no longer in the library',
      );
      expect(
        msg(_s(songs: 2, added: 2, dropped: 3)),
        'Added 2 songs to “Chill”, 3 songs no longer in the library',
      );
    });

    test('a second sentence names the playlists deleted meanwhile', () {
      expect(
        msg(_s(songs: 3, added: 3, gone: 1)),
        'Added 3 songs to “Chill”. 1 playlist was deleted meanwhile',
      );
      expect(
        msg(_s(songs: 3, playlists: 2, dropped: 1, gone: 2)),
        'Added 3 songs to 2 playlists, 1 song no longer in the library. '
        '2 playlists were deleted meanwhile',
      );
    });

    test('nothing written anywhere is a failure, gone or not', () {
      expect(msg(_s(failed: true)), en.playlistAddFailed);
      expect(
        msg(_s(failed: true, gone: 2, playlists: 0, songs: 0)),
        en.playlistAddFailed,
      );
    });
  });

  group('vietnamese', () {
    String msg(AddSummary s) => addToPlaylistMessage(vi, s);

    test('one and several targets', () {
      expect(msg(_s()), 'Đã thêm 1 bài vào “Chill”');
      expect(
        msg(_s(songs: 3, playlists: 3, created: 1)),
        'Đã thêm 3 bài vào 3 playlist (1 mới)',
      );
      expect(
        msg(_s(songs: 3, playlists: 2, skipped: 2)),
        'Đã thêm 3 bài vào 2 playlist, bỏ qua 2',
      );
    });

    test('suffixes join with their own comma', () {
      expect(
        msg(_s(songs: 2, added: 2, skippedOne: 1, moved: 1, dropped: 1)),
        'Đã thêm 2 bài vào “Chill”, bỏ qua 1, bỏ 1 bản cũ, '
        '1 bài không còn trong thư viện',
      );
    });

    test('nothing new, gone sentence and failure', () {
      expect(
        msg(_s(added: 0, nothingNew: true)),
        'Mọi bài đã có trong “Chill”',
      );
      expect(
        msg(_s(playlists: 2, songs: 0, nothingNew: true)),
        'Mọi bài đã có trong 2 playlist',
      );
      expect(
        msg(_s(gone: 1)),
        'Đã thêm 1 bài vào “Chill”. 1 playlist đã bị xoá trong lúc đó',
      );
      expect(msg(_s(failed: true)), 'Không thêm được vào playlist');
    });
  });
}
