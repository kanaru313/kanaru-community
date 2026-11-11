import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/media_controls/mpris/mpris_object.dart';
import 'package:kanaru/src/platform/data/media_controls/mpris/mpris_properties.dart';
import 'package:kanaru/src/platform/domain/media_controls.dart';

const _item = MediaControlsItem(
  id: '7',
  title: 'T',
  duration: Duration(seconds: 100),
);
const _state = MediaControlsState(
  playing: true,
  stopped: false,
  started: true,
  canPlay: true,
  canSeek: true,
);

void main() {
  late List<MediaCommand> posted;
  late MprisSnapshot snap;
  var active = true;
  late MprisObject obj;

  setUp(() {
    posted = [];
    active = true;
    snap = (item: _item, state: _state, position: const Duration(seconds: 40));
    obj = MprisObject(
      snapshot: () => snap,
      post: posted.add,
      isActive: () => active,
    );
  });

  DBusMethodCall call(String name, [List<DBusValue> values = const [], String iface = mprisPlayerInterface]) =>
      DBusMethodCall(sender: ':1.1', interface: iface, name: name, values: values);

  Future<String?> errorOf(Future<DBusMethodResponse> f) async {
    final r = await f;
    return r is DBusMethodErrorResponse ? r.errorName : null;
  }

  const invalid = 'org.freedesktop.DBus.Error.InvalidArgs';

  group('methods', () {
    test('transport methods reply at once and post the command', () async {
      for (final (name, expected) in [
        ('Play', isA<Play>()),
        ('Pause', isA<Pause>()),
        ('PlayPause', isA<PlayPause>()),
        ('Stop', isA<Stop>()),
        ('Next', isA<Next>()),
        ('Previous', isA<Previous>()),
      ]) {
        posted.clear();
        final r = await obj.handleMethodCall(call(name));
        expect(r, isA<DBusMethodSuccessResponse>(), reason: name);
        expect(posted.single, expected, reason: name);
      }
    });

    test('arguments where none belong are refused', () async {
      expect(await errorOf(obj.handleMethodCall(call('Play', [const DBusInt32(1)]))), invalid);
      expect(posted, isEmpty);
    });

    test('Seek posts the offset', () async {
      await obj.handleMethodCall(call('Seek', [const DBusInt64(5000000)]));
      expect((posted.single as Seek).offset, const Duration(seconds: 5));
    });

    test('Seek past the end is Next', () async {
      await obj.handleMethodCall(call('Seek', [const DBusInt64(70000000)]));
      expect(posted.single, isA<Next>());
    });

    test('Seek before the start goes to the start', () async {
      await obj.handleMethodCall(call('Seek', [const DBusInt64(-90000000)]));
      expect((posted.single as Seek).offset, const Duration(seconds: -40));
    });

    test('a huge offset cannot overflow', () async {
      await obj.handleMethodCall(call('Seek', [const DBusInt64(9223372036854775807)]));
      expect(posted.single, isA<Next>());
      posted.clear();
      await obj.handleMethodCall(call('Seek', [const DBusInt64(-9223372036854775807)]));
      expect((posted.single as Seek).offset, const Duration(seconds: -40));
    });

    test('Seek without a length or with seeking off does nothing', () async {
      snap = (item: _item, state: const MediaControlsState(), position: Duration.zero);
      expect(await obj.handleMethodCall(call('Seek', [const DBusInt64(1)])), isA<DBusMethodSuccessResponse>());
      snap = (item: null, state: _state, position: Duration.zero);
      await obj.handleMethodCall(call('Seek', [const DBusInt64(1)]));
      expect(posted, isEmpty);
    });

    test('Seek with the wrong signature is refused', () async {
      expect(await errorOf(obj.handleMethodCall(call('Seek', [const DBusString('x')]))), invalid);
    });

    test('SetPosition for the current track posts', () async {
      await obj.handleMethodCall(call('SetPosition', [
        DBusObjectPath(mprisTrackPath('7')),
        const DBusInt64(30000000),
      ]));
      final c = posted.single as SetPosition;
      expect((c.id, c.position), ('7', const Duration(seconds: 30)));
    });

    test('SetPosition for a stale track id or out of range is ignored', () async {
      final ok = DBusObjectPath(mprisTrackPath('7'));
      for (final values in [
        [DBusObjectPath(mprisTrackPath('6')), const DBusInt64(1)],
        [ok, const DBusInt64(-1)],
        [ok, const DBusInt64(100000001)],
      ]) {
        final r = await obj.handleMethodCall(call('SetPosition', values));
        expect(r, isA<DBusMethodSuccessResponse>());
      }
      expect(posted, isEmpty);
    });

    test('SetPosition with the wrong signature is refused', () async {
      expect(await errorOf(obj.handleMethodCall(call('SetPosition', [const DBusInt64(1)]))), invalid);
    });

    test('OpenUri is not supported, Quit too, Raise is harmless', () async {
      expect(await errorOf(obj.handleMethodCall(call('OpenUri', [const DBusString('x')]))),
          'org.freedesktop.DBus.Error.NotSupported');
      expect(await errorOf(obj.handleMethodCall(call('Quit', const [], mprisRootInterface))),
          'org.freedesktop.DBus.Error.NotSupported');
      expect(await obj.handleMethodCall(call('Raise', const [], mprisRootInterface)), isA<DBusMethodSuccessResponse>());
    });

    test('unknown method and interface', () async {
      expect(await errorOf(obj.handleMethodCall(call('Dance'))), 'org.freedesktop.DBus.Error.UnknownMethod');
      expect(await errorOf(obj.handleMethodCall(call('Play', const [], 'x.y'))), 'org.freedesktop.DBus.Error.UnknownInterface');
    });
  });

  group('properties', () {
    test('Get, GetAll and unknown names', () async {
      final r = await obj.getProperty(mprisPlayerInterface, 'PlaybackStatus');
      expect((r as DBusGetPropertyResponse).values[0].asVariant(), const DBusString('Playing'));
      final pos = await obj.getProperty(mprisPlayerInterface, 'Position');
      expect((pos as DBusGetPropertyResponse).values[0].asVariant(), const DBusInt64(40000000));
      final all = await obj.getAllProperties(mprisRootInterface);
      expect((all as DBusGetAllPropertiesResponse).values[0].asStringVariantDict()['Identity'], const DBusString('Kanaru'));
      expect(await errorOf(obj.getProperty(mprisPlayerInterface, 'Nope')), 'org.freedesktop.DBus.Error.UnknownProperty');
      expect(await errorOf(obj.getProperty('x.y', 'A')), 'org.freedesktop.DBus.Error.UnknownInterface');
      expect(await errorOf(obj.getAllProperties('x.y')), 'org.freedesktop.DBus.Error.UnknownInterface');
    });

    test('Set LoopStatus, Shuffle and Volume post commands', () async {
      await obj.setProperty(mprisPlayerInterface, 'LoopStatus', const DBusString('Track'));
      await obj.setProperty(mprisPlayerInterface, 'Shuffle', const DBusBoolean(true));
      await obj.setProperty(mprisPlayerInterface, 'Volume', const DBusDouble(2.5));
      expect((posted[0] as SetRepeat).repeat, MediaRepeat.track);
      expect((posted[1] as SetShuffle).on, isTrue);
      expect((posted[2] as SetVolume).volume, 1.0);
    });

    test('Set with a wrong type or value is refused', () async {
      expect(await errorOf(obj.setProperty(mprisPlayerInterface, 'LoopStatus', const DBusString('Sideways'))), invalid);
      expect(await errorOf(obj.setProperty(mprisPlayerInterface, 'LoopStatus', const DBusInt32(1))), invalid);
      expect(await errorOf(obj.setProperty(mprisPlayerInterface, 'Shuffle', const DBusString('x'))), invalid);
      expect(await errorOf(obj.setProperty(mprisPlayerInterface, 'Volume', const DBusDouble(double.nan))), invalid);
      expect(posted, isEmpty);
    });

    test('Rate: 1 accepted, 0 pauses, anything else refused', () async {
      expect(await obj.setProperty(mprisPlayerInterface, 'Rate', const DBusDouble(1)), isA<DBusMethodSuccessResponse>());
      expect(posted, isEmpty);
      await obj.setProperty(mprisPlayerInterface, 'Rate', const DBusDouble(0));
      expect(posted.single, isA<Pause>());
      expect(await errorOf(obj.setProperty(mprisPlayerInterface, 'Rate', const DBusDouble(1.5))), invalid);
    });

    test('read-only and unknown properties', () async {
      expect(await errorOf(obj.setProperty(mprisPlayerInterface, 'Metadata', const DBusString('x'))),
          'org.freedesktop.DBus.Error.PropertyReadOnly');
      expect(await errorOf(obj.setProperty(mprisPlayerInterface, 'Nope', const DBusString('x'))),
          'org.freedesktop.DBus.Error.UnknownProperty');
      expect(await errorOf(obj.setProperty(mprisRootInterface, 'Identity', const DBusString('x'))),
          'org.freedesktop.DBus.Error.PropertyReadOnly');
      expect(await errorOf(obj.setProperty(mprisRootInterface, 'Nope', const DBusString('x'))),
          'org.freedesktop.DBus.Error.UnknownProperty');
    });
  });

  group('guard', () {
    test('a throwing handler answers Failed', () async {
      final bad = MprisObject(
        snapshot: () => throw StateError('boom'),
        post: posted.add,
        isActive: () => true,
      );
      const failed = 'org.freedesktop.DBus.Error.Failed';
      expect(await errorOf(bad.getAllProperties(mprisPlayerInterface)), failed);
      expect(await errorOf(bad.getProperty(mprisPlayerInterface, 'Position')), failed);
      expect(await errorOf(bad.handleMethodCall(call('Seek', [const DBusInt64(1)]))), failed);
    });

    test('a throwing post answers Failed', () async {
      final bad = MprisObject(
        snapshot: () => snap,
        post: (_) => throw StateError('closed'),
        isActive: () => true,
      );
      expect(await errorOf(bad.handleMethodCall(call('Play'))), 'org.freedesktop.DBus.Error.Failed');
    });

    test('a disposed object answers Failed', () async {
      active = false;
      expect(await errorOf(obj.handleMethodCall(call('Play'))), 'org.freedesktop.DBus.Error.Failed');
      expect(await errorOf(obj.getProperty(mprisPlayerInterface, 'Volume')), 'org.freedesktop.DBus.Error.Failed');
      expect(posted, isEmpty);
    });
  });

  test('introspection marks Position and CanControl as not signalled', () {
    final player = obj.introspect().firstWhere((i) => i.name == mprisPlayerInterface);
    for (final name in ['Position', 'CanControl']) {
      final prop = player.properties.firstWhere((p) => p.name == name);
      expect(
        prop.annotations.map((a) => (a.name, a.value)),
        contains(('org.freedesktop.DBus.Property.EmitsChangedSignal', 'false')),
        reason: name,
      );
    }
  });
}
