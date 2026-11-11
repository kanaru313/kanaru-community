import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/media_controls/mpris/mpris_bus_name.dart';
import 'package:kanaru/src/platform/data/media_controls/mpris/mpris_media_controls.dart';
import 'package:kanaru/src/platform/data/media_controls/mpris/mpris_properties.dart';
import 'package:kanaru/src/platform/domain/media_controls.dart';

const _item = MediaControlsItem(
  id: '9',
  title: 'Song',
  artists: ['Artist'],
  album: 'Album',
  duration: Duration(seconds: 120),
);
const _playing = MediaControlsState(
  playing: true,
  stopped: false,
  started: true,
  canPlay: true,
  canNext: true,
  canPrevious: true,
  canSeek: true,
);

/// Waits until [done] is true, at most 3 s (the machine may be busy).
Future<void> until(bool Function() done) async {
  final end = DateTime.now().add(const Duration(seconds: 3));
  while (!done() && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Real MPRIS objects over an in-process bus on a unix socket. Skipped when
/// the sandbox refuses to create the socket.
void main() {
  DBusServer? server;
  late Directory dir;
  late DBusAddress address;
  String? skip;

  setUpAll(() async {
    try {
      dir = await Directory.systemTemp.createTemp('kanaru-dbus');
      server = DBusServer();
      address = await server!.listenAddress(
        DBusAddress.unix(path: '${dir.path}/bus'),
      );
    } on Object catch (e) {
      skip = 'cannot listen on a unix socket here: $e';
    }
  });
  tearDownAll(() async {
    await server?.close();
    if (skip == null) await dir.delete(recursive: true);
  });

  late MprisMediaControls controls;
  late DBusClient peer;
  late DBusRemoteObject remote;
  var busName = mprisBusName;

  Future<void> boot({List<DBusClient> squatters = const []}) async {
    controls = MprisMediaControls(
      createClient: () => DBusClient(address),
      coalesce: const Duration(milliseconds: 40),
      pid: 4242,
    );
    await controls.start();
    busName = controls.busName!;
    peer = DBusClient(address);
    remote = DBusRemoteObject(
      peer,
      name: busName,
      path: DBusObjectPath(mprisObjectPath),
    );
  }

  Future<void> shutdown() async {
    await controls.dispose();
    await peer.close();
  }

  Future<Map<String, DBusValue>> all() =>
      remote.getAllProperties(mprisPlayerInterface);

  test('takes the app name and answers GetAll', () async {
    await boot();
    addTearDown(shutdown);
    expect(busName, mprisBusName);
    await controls.update(_item, _playing);
    final p = await all();
    expect(p['PlaybackStatus'], const DBusString('Playing'));
    expect(p['CanSeek'], const DBusBoolean(true));
    final root = await remote.getAllProperties(mprisRootInterface);
    expect(root['Identity'], const DBusString('Kanaru'));
    expect(root['CanRaise'], const DBusBoolean(false));
  }, skip: skip);

  test('falls back to the instance name when the app name is taken', () async {
    final squatter = DBusClient(address);
    addTearDown(squatter.close);
    await squatter.requestName(
      mprisBusName,
      flags: {DBusRequestNameFlag.doNotQueue},
    );
    await boot();
    addTearDown(shutdown);
    expect(busName, '$mprisBusName.instance4242');
    expect((await all())['PlaybackStatus'], isNotNull);
  }, skip: skip);

  test('PlayPause and Seek reach commands', () async {
    await boot();
    addTearDown(shutdown);
    await controls.update(_item, _playing);
    final seen = <MediaCommand>[];
    final sub = controls.commands.listen(seen.add);
    addTearDown(sub.cancel);
    await remote.callMethod(mprisPlayerInterface, 'PlayPause', const [],
        replySignature: DBusSignature(''));
    await remote.callMethod(
      mprisPlayerInterface,
      'Seek',
      const [DBusInt64(2000000)],
      replySignature: DBusSignature(''),
    );
    await pumpEventQueue();
    expect(seen.first, isA<PlayPause>());
    expect((seen[1] as Seek).offset, const Duration(seconds: 2));
  }, skip: skip);

  test('a bad call is refused over the wire', () async {
    await boot();
    addTearDown(shutdown);
    await expectLater(
      remote.callMethod(
        mprisPlayerInterface,
        'Seek',
        [const DBusString('x')],
        replySignature: DBusSignature(''),
      ),
      throwsA(isA<DBusInvalidArgsException>()),
    );
  }, skip: skip);

  test('one PropertiesChanged per coalesced change, only changed keys', () async {
    await boot();
    addTearDown(shutdown);
    final signals = <DBusPropertiesChangedSignal>[];
    final sub = remote.propertiesChanged
        .where((s) => s.propertiesInterface == mprisPlayerInterface)
        .listen(signals.add);
    addTearDown(sub.cancel);

    // The first update is the diff base; wait for its own signal.
    await controls.update(_item, _playing);
    await until(() => signals.isNotEmpty);
    signals.clear();

    // Three changes inside one window.
    await controls.update(_item, _playing);
    controls.updatePosition(const Duration(seconds: 3));
    const next = MediaControlsItem(id: '10', title: 'Next', duration: Duration(seconds: 60));
    const paused = MediaControlsState(playing: false, stopped: false, started: true, canPlay: true);
    await controls.update(next, paused);
    await until(() => signals.isNotEmpty);
    // A second signal, if the coalescing were broken, would follow at once.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(signals, hasLength(1));
    expect(signals.single.changedProperties.keys.toSet(), {
      'PlaybackStatus', 'Metadata', 'CanGoNext', 'CanGoPrevious', 'CanSeek',
    });
    expect(signals.single.changedProperties.containsKey('Position'), isFalse);

    // The same state again sends nothing.
    signals.clear();
    await controls.update(next, paused);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(signals, isEmpty);
  }, skip: skip);

  test('Seeked goes out after the pending properties', () async {
    await boot();
    addTearDown(shutdown);
    final order = <String>[];
    final a = remote.propertiesChanged
        .where((s) => s.propertiesInterface == mprisPlayerInterface)
        .listen((_) => order.add('props'));
    final b = DBusSignalStream(
      peer,
      sender: busName,
      interface: mprisPlayerInterface,
      name: 'Seeked',
      path: DBusObjectPath(mprisObjectPath),
    ).listen((_) => order.add('seeked'));
    addTearDown(a.cancel);
    addTearDown(b.cancel);

    await controls.update(_item, _playing);
    await until(() => order.isNotEmpty);
    order.clear();

    await controls.update(
      const MediaControlsItem(id: '11', title: 'Other', duration: Duration(seconds: 90)),
      _playing,
    );
    controls.seeked(const Duration(seconds: 30));
    await until(() => order.length >= 2);
    expect(order, ['props', 'seeked']);
    expect((await all())['Position'], const DBusInt64(30000000));
  }, skip: skip);

  test('a connect that finishes after the timeout gives the name back', () async {
    final late = MprisMediaControls(
      createClient: () => DBusClient(address),
      connectTimeout: Duration.zero,
      pid: 77,
    );
    await late.start();
    expect(late.busName, isNull);
    final other = DBusClient(address);
    addTearDown(other.close);
    var got = false;
    await until(() {
      other
          .requestName(mprisBusName, flags: {DBusRequestNameFlag.doNotQueue})
          .then((r) => got = got || r == DBusRequestNameReply.primaryOwner);
      return got;
    });
    expect(got, isTrue, reason: 'the late connection released the name');
    await late.dispose();
  }, skip: skip);

  test('start never throws and stays idle when the bus is gone', () async {
    final dead = MprisMediaControls(
      createClient: () => DBusClient(
        DBusAddress.unix(path: '${Directory.systemTemp.path}/no-such-bus'),
      ),
      connectTimeout: const Duration(seconds: 1),
    );
    await dead.start();
    expect(dead.busName, isNull);
    await dead.update(_item, _playing);
    dead.seeked(Duration.zero);
    await dead.dispose();
  });

  test('a client that is not built is reported as idle', () async {
    final bad = MprisMediaControls(
      createClient: () => throw const FormatException('bad bus address'),
    );
    await bad.start();
    expect(bad.busName, isNull);
    await bad.dispose();
  });

  test('dispose gives the name back', () async {
    await boot();
    final other = DBusClient(address);
    addTearDown(other.close);
    await controls.dispose();
    final reply = await other.requestName(
      mprisBusName,
      flags: {DBusRequestNameFlag.doNotQueue},
    );
    expect(reply, DBusRequestNameReply.primaryOwner);
    await peer.close();
  }, skip: skip);
}
