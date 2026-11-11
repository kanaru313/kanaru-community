import 'package:dbus/dbus.dart';
import 'package:logging/logging.dart';

import '../../../domain/media_controls.dart';
import 'mpris_introspection.dart';
import 'mpris_properties.dart';

final _log = Logger('mpris');

/// What the object answers from: the published item and state and the live
/// position.
typedef MprisSnapshot = ({
  MediaControlsItem? item,
  MediaControlsState state,
  Duration position,
});

/// `/org/mpris/MediaPlayer2` with the two MPRIS interfaces.
///
/// `dbus` does not catch what a handler throws, which leaves the caller
/// waiting for a reply that never comes, so every entry point is guarded and
/// answers `Failed` instead. Methods validate their arguments, reply at once
/// and hand a [MediaCommand] to [_post]; the player runs it later.
class MprisObject extends DBusObject {
  MprisObject({
    required this._snapshot,
    required this._post,
    required this._isActive,
  }) : super(DBusObjectPath(mprisObjectPath));

  final MprisSnapshot Function() _snapshot;
  final void Function(MediaCommand) _post;
  final bool Function() _isActive;

  Map<String, DBusValue>? _properties(String interface) {
    switch (interface) {
      case mprisRootInterface:
        return mprisRootProperties();
      case mprisPlayerInterface:
        final s = _snapshot();
        return mprisPlayerProperties(s.item, s.state, position: s.position);
      default:
        return null;
    }
  }

  Future<DBusMethodResponse> _guard(
    String what,
    DBusMethodResponse Function() body,
  ) async {
    if (!_isActive()) return DBusMethodErrorResponse.failed();
    try {
      return body();
    } on Object catch (error, stack) {
      _log.severe('$what failed', error, stack);
      return DBusMethodErrorResponse.failed();
    }
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) =>
      _guard(methodCall.name, () {
        return switch (methodCall.interface) {
          mprisRootInterface => _root(methodCall),
          mprisPlayerInterface => _player(methodCall),
          _ => DBusMethodErrorResponse.unknownInterface(),
        };
      });

  DBusMethodResponse _root(DBusMethodCall call) => switch (call.name) {
    // CanRaise is false: there is nothing to raise, and asking is harmless.
    'Raise' =>
      call.signature == DBusSignature('')
          ? DBusMethodSuccessResponse()
          : DBusMethodErrorResponse.invalidArgs(),
    'Quit' => DBusMethodErrorResponse.notSupported(),
    _ => DBusMethodErrorResponse.unknownMethod(),
  };

  DBusMethodResponse _player(DBusMethodCall call) => switch (call.name) {
    'Play' => _simple(call, const Play()),
    'Pause' => _simple(call, const Pause()),
    'PlayPause' => _simple(call, const PlayPause()),
    'Stop' => _simple(call, const Stop()),
    'Next' => _simple(call, const Next()),
    'Previous' => _simple(call, const Previous()),
    'Seek' => _seek(call),
    'SetPosition' => _setPosition(call),
    'OpenUri' =>
      call.signature != DBusSignature('s')
          ? DBusMethodErrorResponse.invalidArgs()
          : DBusMethodErrorResponse.notSupported(),
    _ => DBusMethodErrorResponse.unknownMethod(),
  };

  DBusMethodResponse _simple(DBusMethodCall call, MediaCommand command) {
    if (call.signature != DBusSignature('')) {
      return DBusMethodErrorResponse.invalidArgs();
    }
    _post(command);
    return DBusMethodSuccessResponse();
  }

  /// `Seek(offset)`: past the end is Next, before the start is the start.
  DBusMethodResponse _seek(DBusMethodCall call) {
    if (call.signature != DBusSignature('x')) {
      return DBusMethodErrorResponse.invalidArgs();
    }
    final s = _snapshot();
    final length = s.item?.duration;
    if (length == null || length <= Duration.zero || !s.state.canSeek) {
      return DBusMethodSuccessResponse();
    }
    final lengthUs = length.inMicroseconds;
    // Clamped first so the sum below cannot overflow int64.
    final offset = call.values[0].asInt64().clamp(-lengthUs, lengthUs);
    final target = s.position.inMicroseconds + offset;
    if (target >= lengthUs) {
      _post(const Next());
    } else if (target < 0) {
      _post(Seek(-s.position));
    } else {
      _post(Seek(Duration(microseconds: offset)));
    }
    return DBusMethodSuccessResponse();
  }

  /// `SetPosition(trackId, position)`: only for the current item and a
  /// position inside it; anything else is ignored, as the spec says.
  DBusMethodResponse _setPosition(DBusMethodCall call) {
    if (call.signature != DBusSignature('ox')) {
      return DBusMethodErrorResponse.invalidArgs();
    }
    final s = _snapshot();
    final item = s.item;
    final length = s.item?.duration;
    final position = call.values[1].asInt64();
    if (item != null &&
        length != null &&
        length > Duration.zero &&
        call.values[0].asObjectPath() ==
            DBusObjectPath(mprisTrackPath(item.id)) &&
        position >= 0 &&
        position <= length.inMicroseconds) {
      _post(SetPosition(item.id, Duration(microseconds: position)));
    }
    return DBusMethodSuccessResponse();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) =>
      _guard('Get $name', () {
        final props = _properties(interface);
        if (props == null) return DBusMethodErrorResponse.unknownInterface();
        final value = props[name];
        if (value == null) return DBusMethodErrorResponse.unknownProperty();
        return DBusGetPropertyResponse(value);
      });

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) =>
      _guard('GetAll', () {
        final props = _properties(interface);
        if (props == null) return DBusMethodErrorResponse.unknownInterface();
        return DBusGetAllPropertiesResponse(props);
      });

  @override
  Future<DBusMethodResponse> setProperty(
    String interface,
    String name,
    DBusValue value,
  ) => _guard('Set $name', () {
    switch (interface) {
      case mprisPlayerInterface:
        return _setPlayerProperty(name, value);
      case mprisRootInterface:
        return mprisRootProperties().containsKey(name)
            ? DBusMethodErrorResponse.propertyReadOnly()
            : DBusMethodErrorResponse.unknownProperty();
      default:
        return DBusMethodErrorResponse.unknownInterface();
    }
  });

  DBusMethodResponse _setPlayerProperty(String name, DBusValue value) {
    switch (name) {
      case 'LoopStatus':
        if (value is! DBusString) return DBusMethodErrorResponse.invalidArgs();
        final repeat = mediaRepeatFromLoopStatus(value.value);
        if (repeat == null) return DBusMethodErrorResponse.invalidArgs();
        _post(SetRepeat(repeat));
      case 'Shuffle':
        if (value is! DBusBoolean) return DBusMethodErrorResponse.invalidArgs();
        _post(SetShuffle(value.value));
      case 'Volume':
        if (value is! DBusDouble || !value.value.isFinite) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        _post(SetVolume(value.value.clamp(0, 1).toDouble()));
      case 'Rate':
        // Only 1.0 is supported; the spec says 0.0 means Pause.
        if (value is! DBusDouble || (value.value != 1 && value.value != 0)) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        if (value.value == 0) _post(const Pause());
      default:
        return mprisPlayerProperties(null, const MediaControlsState())
                .containsKey(name)
            ? DBusMethodErrorResponse.propertyReadOnly()
            : DBusMethodErrorResponse.unknownProperty();
    }
    return DBusMethodSuccessResponse();
  }

  @override
  List<DBusIntrospectInterface> introspect() => mprisIntrospection();
}
