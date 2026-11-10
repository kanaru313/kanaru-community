import 'dart:async';
import 'dart:io' as io;

import 'package:dbus/dbus.dart';
import 'package:logging/logging.dart';

import '../../../domain/media_controls.dart';
import 'mpris_bus_name.dart';
import 'mpris_object.dart';
import 'mpris_properties.dart';

final _log = Logger('mpris');

/// Changes within this window go out as one `PropertiesChanged`: a track
/// change moves several properties, and the length arrives after the title.
const mprisCoalesceWindow = Duration(milliseconds: 150);

/// The most [MprisMediaControls.start] waits for the bus.
const mprisConnectTimeout = Duration(seconds: 3);

const _closeTimeout = Duration(seconds: 1);

/// MPRIS 2.2 on the D-Bus session bus. Publishes what the player tells it
/// and turns media keys, `playerctl` and desktop widgets into [commands].
///
/// [start] never throws: with no bus, no free name or no answer within
/// [mprisConnectTimeout] it logs and stays idle. It does not reconnect when
/// the bus goes away; the first failed send marks the bus as lost.
class MprisMediaControls implements MediaControls {
  MprisMediaControls({
    DBusClient Function()? createClient,
    this.coalesce = mprisCoalesceWindow,
    this.connectTimeout = mprisConnectTimeout,
    int? pid,
  }) : _createClient = createClient ?? DBusClient.session,
       _pid = pid ?? io.pid {
    _object = MprisObject(
      snapshot: () => (item: _item, state: _state, position: _position),
      post: _commands.add,
      isActive: () => !_disposed,
    );
  }

  final Duration coalesce;
  final Duration connectTimeout;
  final DBusClient Function() _createClient;
  final int _pid;
  final _commands = StreamController<MediaCommand>.broadcast();
  late final MprisObject _object;
  DBusClient? _client;
  Future<void>? _starting;

  MediaControlsItem? _item;
  MediaControlsState _state = const MediaControlsState();
  Duration _position = Duration.zero;

  /// The properties as last sent (or read at start); the diff base.
  Map<String, DBusValue> _emitted = const {};
  Timer? _timer;
  String? _ownedName;
  bool _active = false;
  bool _disposed = false;
  bool _timedOut = false;
  bool _lost = false;

  /// Nobody waits for the connection any more.
  bool get _gaveUp => _disposed || _timedOut;

  /// The bus name in use; null while idle.
  String? get busName => _active ? _ownedName : null;

  @override
  Stream<MediaCommand> get commands => _commands.stream;

  @override
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    try {
      await _connect().timeout(connectTimeout);
    } on TimeoutException {
      _timedOut = true;
      _log.warning('MPRIS: the bus did not answer, controls stay off');
    } on Object catch (error) {
      // The usual reasons (no session bus, bus refused us): one line.
      _log.warning('MPRIS unavailable: $error');
    }
  }

  Future<void> _connect() async {
    final client = _client = _createClient();
    await client.registerObject(_object);
    if (_gaveUp) {
      _abandonIfLate(client, null);
      return;
    }
    final name = await acquireMprisBusName(
      (n) => client.requestName(n, flags: {DBusRequestNameFlag.doNotQueue}),
      pid: _pid,
      cancelled: () => _gaveUp,
    );
    if (name == null) {
      _abandonIfLate(client, null);
      return;
    }
    // Kept even when disposed meanwhile, so dispose can give it back.
    _ownedName = name;
    if (_gaveUp) {
      _abandonIfLate(client, name);
      return;
    }
    _emitted = _build();
    _active = true;
  }

  /// The connection finished after [start] gave up (timeout): nobody will
  /// publish through it, so it must not keep the bus name and answer with
  /// stale state. After a dispose, dispose itself gives everything back.
  void _abandonIfLate(DBusClient client, String? name) {
    if (_disposed || !_timedOut) return;
    _client = null;
    _ownedName = null;
    unawaited(() async {
      if (name != null) await _bounded('release', client.releaseName(name));
      await _bounded('close', client.close());
    }());
  }

  Map<String, DBusValue> _build() =>
      mprisPlayerProperties(_item, _state, position: _position);

  @override
  Future<void> update(MediaControlsItem? item, MediaControlsState state) async {
    _item = item;
    _state = state;
    _position = state.position;
    if (_active && !_disposed) _timer ??= Timer(coalesce, _flush);
  }

  @override
  void updatePosition(Duration position) => _position = position;

  /// Sends the changed properties now. Runs from a timer or before `Seeked`,
  /// so it never throws.
  void _flush() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || !_active) return;
    final latest = _build();
    final changed = mprisChangedProperties(_emitted, latest);
    _emitted = latest;
    if (changed.isEmpty) return;
    _send(
      _object.emitPropertiesChanged(
        mprisPlayerInterface,
        changedProperties: changed,
      ),
    );
  }

  @override
  void seeked(Duration position) {
    _position = position;
    if (_disposed || !_active) return;
    // Clients that see Seeked before the new Metadata would show the old
    // length: pending properties go first.
    _flush();
    _send(
      _object.emitSignal(mprisPlayerInterface, 'Seeked', [
        DBusInt64(position.inMicroseconds),
      ]),
    );
  }

  /// Sends in the background. A failed send (the bus went away) is logged
  /// once and ends all further sending.
  void _send(Future<void> emit) {
    if (_lost) return;
    unawaited(
      emit.catchError((Object error) {
        if (_lost) return;
        _lost = true;
        _active = false;
        _log.warning('MPRIS: lost the bus, no more updates', error);
      }),
    );
  }

  @override
  Future<bool> activate() async => true;

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _active = false;
    _timer?.cancel();
    // Let a start that still waits on the bus finish, so the name it may be
    // about to get is released too.
    final starting = _starting;
    if (starting != null) await _bounded('start', starting);
    final client = _client;
    final name = _ownedName;
    if (client != null) {
      if (name != null) await _bounded('release', client.releaseName(name));
      await _bounded('close', client.close());
    }
    await _commands.close();
  }

  /// A client that never connected never completes its calls: do not wait
  /// for them past [_closeTimeout].
  Future<void> _bounded(String what, Future<Object?> future) async {
    try {
      await future.timeout(_closeTimeout);
    } on Object catch (error) {
      _log.warning('MPRIS: $what on shutdown failed: $error');
    }
  }
}
