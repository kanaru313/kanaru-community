import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/media_controls/mpris/mpris_properties.dart';
import 'package:kanaru/src/platform/domain/media_controls.dart';

const _item = MediaControlsItem(
  id: '42',
  title: 'Song',
  artists: ['A', 'B'],
  album: 'Album',
  duration: Duration(seconds: 200),
);

const _playing = MediaControlsState(
  playing: true,
  stopped: false,
  started: true,
  canPlay: true,
  canNext: true,
  canPrevious: true,
  canSeek: true,
  shuffle: true,
  repeat: MediaRepeat.playlist,
  volume: 0.5,
);

Map<String, DBusValue> meta(DBusValue v) =>
    (v as DBusDict).children.map((k, v) => MapEntry((k as DBusString).value, (v as DBusVariant).value));

void main() {
  group('root', () {
    test('fixed identity, no raise or quit, no track list', () {
      final r = mprisRootProperties();
      expect(r['Identity'], const DBusString('Kanaru'));
      expect(r['DesktopEntry'], const DBusString('io.github.kanaru313.kanaru_community'));
      expect(r['CanRaise'], const DBusBoolean(false));
      expect(r['CanQuit'], const DBusBoolean(false));
      expect(r['HasTrackList'], const DBusBoolean(false));
      expect(r['SupportedUriSchemes'], DBusArray.string(const []));
      expect(r['SupportedMimeTypes'], DBusArray.string(const []));
    });
  });

  group('metadata', () {
    test('exact key list with the right types', () {
      final m = meta(mprisMetadata(
        MediaControlsItem(
          id: _item.id,
          title: _item.title,
          artists: _item.artists,
          album: _item.album,
          duration: _item.duration,
          artUri: Uri.file('/cache/covers/full/ab/cd.jpg'),
        ),
      ));
      expect(m.keys.toSet(), {
        'mpris:trackid',
        'mpris:length',
        'xesam:title',
        'xesam:artist',
        'xesam:album',
        'mpris:artUrl',
      });
      expect(m['mpris:trackid'], isA<DBusObjectPath>());
      expect(m['mpris:trackid'], DBusObjectPath('/io/github/kanaru313/kanaru_community/entry/42'));
      expect(m['mpris:length'], const DBusInt64(200000000));
      expect(m['xesam:artist'], DBusArray.string(const ['A', 'B']));
      expect(m['xesam:album'], const DBusString('Album'));
      expect(m['mpris:artUrl'], const DBusString('file:///cache/covers/full/ab/cd.jpg'));
    });

    test('empty strings and an unknown length are left out', () {
      final m = meta(mprisMetadata(const MediaControlsItem(
        id: '1',
        title: '',
        artists: ['', 'X', ''],
        album: '',
      )));
      expect(m.keys.toSet(), {'mpris:trackid', 'xesam:artist'});
      expect(m['xesam:artist'], DBusArray.string(const ['X']));
    });

    test('a zero length is left out', () {
      final m = meta(mprisMetadata(const MediaControlsItem(
        id: '1',
        title: 't',
        duration: Duration.zero,
      )));
      expect(m.containsKey('mpris:length'), isFalse);
    });

    test('no item: only the no-track id', () {
      final m = meta(mprisMetadata(null));
      expect(m, {'mpris:trackid': DBusObjectPath(mprisNoTrackPath)});
    });

    test('a # in a path is escaped in the art URL', () {
      final url = mprisArtUrl(Uri.file('/c/a#b.jpg'));
      expect(url, 'file:///c/a%23b.jpg');
      expect(Uri.parse(url!).toFilePath(), '/c/a#b.jpg');
    });

    test('a network art address is dropped', () {
      expect(mprisArtUrl(Uri.parse('http://127.0.0.1:9/cover?token=x')), isNull);
      expect(mprisArtUrl(Uri.parse('https://example.org/a.jpg')), isNull);
      expect(mprisArtUrl(null), isNull);
      final m = meta(mprisMetadata(MediaControlsItem(
        id: '1',
        title: 't',
        artUri: Uri.parse('http://x/y'),
      )));
      expect(m.containsKey('mpris:artUrl'), isFalse);
    });

    test('ids with odd characters stay valid object paths', () {
      expect(DBusObjectPath(mprisTrackPath('a-b c/d')), isNotNull);
    });
  });

  group('player properties', () {
    test('key list and values', () {
      final p = mprisPlayerProperties(_item, _playing, position: const Duration(seconds: 3));
      expect(p.keys.toSet(), {
        'PlaybackStatus', 'LoopStatus', 'Rate', 'Shuffle', 'Metadata',
        'Volume', 'Position', 'MinimumRate', 'MaximumRate', 'CanGoNext',
        'CanGoPrevious', 'CanPlay', 'CanPause', 'CanSeek', 'CanControl',
      });
      expect(p['PlaybackStatus'], const DBusString('Playing'));
      expect(p['LoopStatus'], const DBusString('Playlist'));
      expect(p['Shuffle'], const DBusBoolean(true));
      expect(p['Volume'], const DBusDouble(0.5));
      expect(p['Position'], const DBusInt64(3000000));
      expect(p['Rate'], const DBusDouble(1));
      expect(p['CanControl'], const DBusBoolean(true));
    });

    test('status: paused, stopped (from app state) and empty', () {
      expect(mprisPlaybackStatus(_item, const MediaControlsState(playing: false, stopped: false)), 'Paused');
      // The engine may still say playing right after a stop.
      expect(mprisPlaybackStatus(_item, const MediaControlsState(playing: true, stopped: true)), 'Stopped');
      expect(mprisPlaybackStatus(null, _playing), 'Stopped');
    });

    test('loop status maps both ways', () {
      for (final r in MediaRepeat.values) {
        expect(mediaRepeatFromLoopStatus(mprisLoopStatus(r)), r);
      }
      expect(mediaRepeatFromLoopStatus('Sideways'), isNull);
    });

    test('volume is clamped into 0..1', () {
      const loud = MediaControlsState(volume: 3);
      expect(mprisPlayerProperties(null, loud)['Volume'], const DBusDouble(1));
    });
  });

  group('changed properties', () {
    test('only differing, signalled keys', () {
      final a = mprisPlayerProperties(_item, _playing);
      final b = mprisPlayerProperties(
        _item,
        const MediaControlsState(
          playing: false, stopped: false, started: true, canPlay: true,
          canNext: true, canPrevious: true, canSeek: true, shuffle: true,
          repeat: MediaRepeat.playlist, volume: 0.5,
        ),
        position: const Duration(minutes: 3),
      );
      expect(mprisChangedProperties(a, b).keys, ['PlaybackStatus']);
    });

    test('Position and CanControl are never signalled', () {
      final a = {'Position': const DBusInt64(1), 'CanControl': const DBusBoolean(true)};
      final b = {'Position': const DBusInt64(2), 'CanControl': const DBusBoolean(false)};
      expect(mprisChangedProperties(a, b), isEmpty);
    });

    test('identical maps change nothing', () {
      final a = mprisPlayerProperties(_item, _playing);
      expect(mprisChangedProperties(a, mprisPlayerProperties(_item, _playing)), isEmpty);
    });
  });
}
