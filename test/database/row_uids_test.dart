import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/row_uids.dart';

void main() {
  const source = 'src:6fbc6d9e3d2c491a';

  test('uids match fixed vectors', () {
    expect(
      sourceUidForRemote('webdav', 'me@example.com', 'https://dav.example.com/music'),
      source,
    );
    expect(sourceUidForRemote('subsonic', null, 'https://s.example.com'),
        'src:0566d70447e1e74e');
    expect(trackUid(source, 'Album/01 Song.flac'), 'trk:e9b2b3ee6541df64');
    expect(excludedFolderUid(source, 'Album/Live'), 'exc:8415b74502fb6c3c');
  });

  test('same locator under another source gives another track uid', () {
    expect(trackUid('src:a', 'x.flac'), isNot(trackUid('src:b', 'x.flac')));
  });

  test('a missing account equals an empty account', () {
    expect(sourceUidForRemote('s3', null, 'bucket/p'),
        sourceUidForRemote('s3', '', 'bucket/p'));
  });

  test('rejects a root with userinfo or a query string', () {
    expect(() => sourceUidForRemote('webdav', null, 'https://u:p@host/x'),
        throwsArgumentError);
    expect(() => sourceUidForRemote('webdav', null, 'user:pass@dav.host/x'),
        throwsArgumentError);
    expect(() => sourceUidForRemote('webdav', null, 'https://host/x?token=1'),
        throwsArgumentError);
  });

  test('the error does not echo the rejected root', () {
    try {
      sourceUidForRemote('webdav', null, 'https://u:secret@host/x');
      fail('expected ArgumentError');
    } on ArgumentError catch (e) {
      expect(e.toString(), isNot(contains('secret')));
    }
  });

  test('accepts ids and bucket roots', () {
    expect(() => sourceUidForRemote('plugin', null, 'plugin-ab12cd34'), returnsNormally);
    expect(() => sourceUidForRemote('s3', null, 's3://bucket/prefix'), returnsNormally);
  });

  test('collection uids match fixed vectors', () {
    expect(favoritesPlaylistUid, 'favorites');
    expect(favoriteEntryUid('favorites', 'trk:e9b2b3ee6541df64'), 'fav:a5e3651578a93b10');
    expect(savedItemUid(source, 'album', 'alb-1'), 'saved:0fbbf90b59213acb');
  });

  test('saved item uid depends on kind and remote id', () {
    expect(savedItemUid('src:a', 'album', '1'),
        isNot(savedItemUid('src:a', 'artist', '1')));
    expect(savedItemUid('src:a', 'album', '1'),
        isNot(savedItemUid('src:a', 'album', '2')));
  });
}
