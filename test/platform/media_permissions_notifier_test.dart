import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/state/media_permissions_provider.dart';

const _granted = MediaPermissionStatus.granted;
const _denied = MediaPermissionStatus.denied;

class _Port implements MediaPermissions {
  _Port(this.state);

  MediaPermissionState state;
  final List<String> calls = [];
  MediaPermissionState Function(MediaPermissionState)? onAudio, onImages;
  bool failStatus = false;

  @override
  Future<MediaPermissionState> status() async {
    calls.add('status');
    if (failStatus) throw StateError('plugin gone');
    return state;
  }

  @override
  Future<MediaPermissionState> requestAudio() async {
    calls.add('audio');
    return state = onAudio?.call(state) ?? state;
  }

  @override
  Future<MediaPermissionState> requestImages() async {
    calls.add('images');
    return state = onImages?.call(state) ?? state;
  }

  @override
  Future<bool> openSettings() async {
    calls.add('settings');
    return true;
  }
}

MediaPermissionState _s(MediaPermissionStatus a, MediaPermissionStatus i) =>
    MediaPermissionState(audio: a, images: i);

void main() {
  late _Port port;
  late ProviderContainer c;

  ProviderContainer make(_Port p) {
    port = p;
    final container = ProviderContainer(
      overrides: [mediaPermissionsProvider.overrideWithValue(p)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads the status once', () async {
    c = make(_Port(_s(_denied, _denied)));
    final state = await c.read(mediaPermissionStateProvider.future);
    expect(state, _s(_denied, _denied));
    expect(port.calls, ['status']);
  });

  test('request asks for audio, then images once audio is granted', () async {
    c = make(
      _Port(_s(_denied, _denied))
        ..onAudio = ((s) => _s(_granted, s.images))
        ..onImages = ((s) => _s(s.audio, _granted)),
    );
    await c.read(mediaPermissionStateProvider.future);
    final after = await c.read(mediaPermissionStateProvider.notifier).request();
    expect(after, _s(_granted, _granted));
    expect(port.calls, ['status', 'audio', 'images']);
    expect(c.read(mediaPermissionStateProvider).value, after);
  });

  test('images are not asked while audio is missing', () async {
    c = make(_Port(_s(_denied, _denied)));
    await c.read(mediaPermissionStateProvider.future);
    final after = await c.read(mediaPermissionStateProvider.notifier).request();
    expect(after.audio, _denied);
    expect(port.calls, ['status', 'audio']);
  });

  test('with audio granted only the images are asked', () async {
    c = make(
      _Port(_s(_granted, _denied))..onImages = ((s) => _s(s.audio, _granted)),
    );
    await c.read(mediaPermissionStateProvider.future);
    await c.read(mediaPermissionStateProvider.notifier).request();
    expect(port.calls, ['status', 'images']);
  });

  test('a limited photo choice is not granted and stays limited', () async {
    c = make(
      _Port(_s(_granted, _denied))
        ..onImages = ((s) => _s(s.audio, MediaPermissionStatus.limited)),
    );
    await c.read(mediaPermissionStateProvider.future);
    final after = await c.read(mediaPermissionStateProvider.notifier).request();
    expect(after.images, MediaPermissionStatus.limited);
    expect(after.allGranted, isFalse);
  });

  test('nothing is asked when everything is granted', () async {
    c = make(_Port(_s(_granted, _granted)));
    await c.read(mediaPermissionStateProvider.future);
    await c.read(mediaPermissionStateProvider.notifier).request();
    expect(port.calls, ['status']);
  });

  test('refresh reads again and updates the state', () async {
    c = make(_Port(_s(_denied, _denied)));
    await c.read(mediaPermissionStateProvider.future);
    port.state = _s(_granted, _granted);
    final next = await c.read(mediaPermissionStateProvider.notifier).refresh();
    expect(next, _s(_granted, _granted));
    expect(c.read(mediaPermissionStateProvider).value, next);
  });

  test('a failed refresh keeps the last value', () async {
    c = make(_Port(_s(_granted, _denied)));
    await c.read(mediaPermissionStateProvider.future);
    port.failStatus = true;
    final next = await c.read(mediaPermissionStateProvider.notifier).refresh();
    expect(next, _s(_granted, _denied));
    expect(c.read(mediaPermissionStateProvider).value, _s(_granted, _denied));
  });

  test('openSettings goes to the port', () async {
    c = make(_Port(_s(_denied, _denied)));
    await c.read(mediaPermissionStateProvider.future);
    expect(
      await c.read(mediaPermissionStateProvider.notifier).openSettings(),
      isTrue,
    );
    expect(port.calls.last, 'settings');
  });
}
