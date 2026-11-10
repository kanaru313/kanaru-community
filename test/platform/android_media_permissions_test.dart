import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/permissions/android_media_permissions.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  final status = <Permission, PermissionStatus>{};
  final requestResult = <Permission, PermissionStatus>{};
  var requests = 0;
  Completer<void>? gate;

  AndroidMediaPermissions make({Future<int> Function()? sdk}) =>
      AndroidMediaPermissions(
        sdkInt: sdk ?? () async => 34,
        readStatus: (p) async => status[p] ?? PermissionStatus.denied,
        requestPermission: (p) async {
          requests++;
          await gate?.future;
          return requestResult[p] ?? status[p] ?? PermissionStatus.denied;
        },
      );

  setUp(() {
    status.clear();
    requestResult.clear();
    requests = 0;
    gate = null;
  });

  test('a permanent denial survives later denied reads until granted', () async {
    final perms = make();
    status[Permission.audio] = PermissionStatus.permanentlyDenied;
    var state = await perms.requestAudio();
    expect(state.audio, MediaPermissionStatus.permanentlyDenied);

    // The plugin now reports the permanent denial as plain denied.
    status[Permission.audio] = PermissionStatus.denied;
    state = await perms.status();
    expect(state.audio, MediaPermissionStatus.permanentlyDenied);

    status[Permission.audio] = PermissionStatus.granted;
    state = await perms.status();
    expect(state.audio, MediaPermissionStatus.granted);

    // Revoked later in settings: asked again, not sent to settings.
    status[Permission.audio] = PermissionStatus.denied;
    state = await perms.status();
    expect(state.audio, MediaPermissionStatus.denied);
  });

  test('limited photo access is not granted', () async {
    final perms = make();
    status[Permission.audio] = PermissionStatus.granted;
    status[Permission.photos] = PermissionStatus.limited;
    final state = await perms.requestImages();
    expect(state.images, MediaPermissionStatus.limited);
    expect(state.allGranted, isFalse);
  });

  test('a failing sdkInt is reported as denied, not thrown', () async {
    final perms = make(sdk: () async => throw Exception('channel down'));
    expect((await perms.status()).audio, MediaPermissionStatus.denied);
    expect((await perms.requestAudio()).images, MediaPermissionStatus.denied);
  });

  test('concurrent requests share the one in flight', () async {
    final perms = make();
    gate = Completer<void>();
    status[Permission.audio] = PermissionStatus.granted;
    final first = perms.requestAudio();
    final second = perms.requestAudio();
    await Future<void>.delayed(Duration.zero);
    gate!.complete();
    final states = await Future.wait([first, second]);
    expect(requests, 1);
    expect(states[0], states[1]);
  });

  test('requests for different rows run one after the other', () async {
    final perms = make();
    gate = Completer<void>();
    final order = <String>[];
    final audio = perms.requestAudio().then((_) => order.add('audio'));
    final images = perms.requestImages().then((_) => order.add('images'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(requests, 1, reason: 'second dialog waits for the first');
    gate!.complete();
    await Future.wait([audio, images]);
    expect(requests, 2);
    expect(order, ['audio', 'images']);
  });

  test('a status read during a request keeps the permanent denial', () async {
    final perms = make();
    gate = Completer<void>();
    requestResult[Permission.audio] = PermissionStatus.permanentlyDenied;
    status[Permission.audio] = PermissionStatus.denied;
    final request = perms.requestAudio();
    final read = perms.status();
    await Future<void>.delayed(Duration.zero);
    gate!.complete();
    await request;
    final during = await read;
    expect(during.audio, MediaPermissionStatus.permanentlyDenied);
    expect((await perms.status()).audio, MediaPermissionStatus.permanentlyDenied);
  });

  test('a request that finishes during a status read keeps its denial',
      () async {
    final hold = Completer<void>();
    var firstRead = true;
    final perms = AndroidMediaPermissions(
      sdkInt: () async => 34,
      readStatus: (p) async {
        if (firstRead) {
          firstRead = false;
          await hold.future;
        }
        return PermissionStatus.denied;
      },
      requestPermission: (p) async => PermissionStatus.permanentlyDenied,
    );
    final read = perms.status(); // its first read is held
    await Future<void>.delayed(Duration.zero);
    await perms.requestAudio(); // finishes while the read is held
    hold.complete();
    await read;
    expect((await perms.status()).audio, MediaPermissionStatus.permanentlyDenied);
  });

  test('a status read stops waiting for a request that never ends', () async {
    final never = Completer<void>();
    final perms = AndroidMediaPermissions(
      sdkInt: () async => 34,
      readStatus: (p) async => PermissionStatus.denied,
      requestPermission: (p) async {
        await never.future;
        return PermissionStatus.denied;
      },
      statusWait: const Duration(milliseconds: 50),
    );
    unawaited(perms.requestAudio());
    final state = await perms.status().timeout(const Duration(seconds: 2));
    expect(state.audio, MediaPermissionStatus.denied);
  });
}
