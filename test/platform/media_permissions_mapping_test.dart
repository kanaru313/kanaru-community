import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/permissions/permission_mapping.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('mapStatus', () {
    test('maps every plugin status', () {
      expect(mapStatus(PermissionStatus.granted), MediaPermissionStatus.granted);
      expect(mapStatus(PermissionStatus.denied), MediaPermissionStatus.denied);
      expect(
        mapStatus(PermissionStatus.permanentlyDenied),
        MediaPermissionStatus.permanentlyDenied,
      );
      expect(
        mapStatus(PermissionStatus.restricted),
        MediaPermissionStatus.permanentlyDenied,
      );
      expect(mapStatus(PermissionStatus.limited), MediaPermissionStatus.limited);
      expect(
        mapStatus(PermissionStatus.provisional),
        MediaPermissionStatus.granted,
      );
    });
  });

  group('MediaPermissionState', () {
    MediaPermissionState state(
      MediaPermissionStatus audio,
      MediaPermissionStatus images,
    ) => MediaPermissionState(audio: audio, images: images);

    test('limited is not granted', () {
      final s = state(
        MediaPermissionStatus.granted,
        MediaPermissionStatus.limited,
      );
      expect(s.allGranted, isFalse);
      expect(s.applies, isTrue);
    });

    test('granted and not applicable count as granted', () {
      expect(
        state(MediaPermissionStatus.granted, MediaPermissionStatus.granted)
            .allGranted,
        isTrue,
      );
      const none = MediaPermissionState.notApplicable();
      expect(none.allGranted, isTrue);
      expect(none.applies, isFalse);
    });

    test('anyPermanentlyDenied looks at both rows', () {
      expect(
        state(MediaPermissionStatus.granted, MediaPermissionStatus.permanentlyDenied)
            .anyPermanentlyDenied,
        isTrue,
      );
      expect(
        state(MediaPermissionStatus.denied, MediaPermissionStatus.denied)
            .anyPermanentlyDenied,
        isFalse,
      );
    });
  });

  group('permissionsForSdk', () {
    test('SDK 32 uses the storage permission for both rows', () {
      final p = permissionsForSdk(32);
      expect(p.audio, Permission.storage);
      expect(p.images, Permission.storage);
    });

    test('SDK 33 uses the granular permissions', () {
      final p = permissionsForSdk(33);
      expect(p.audio, Permission.audio);
      expect(p.images, Permission.photos);
    });
  });

  group('mergeStatus', () {
    test('a permanent denial is not downgraded to denied', () {
      expect(
        mergeStatus(
          MediaPermissionStatus.permanentlyDenied,
          MediaPermissionStatus.denied,
        ),
        MediaPermissionStatus.permanentlyDenied,
      );
    });

    test('granted replaces a permanent denial', () {
      expect(
        mergeStatus(
          MediaPermissionStatus.permanentlyDenied,
          MediaPermissionStatus.granted,
        ),
        MediaPermissionStatus.granted,
      );
    });

    test('without an earlier permanent denial the fresh value wins', () {
      expect(
        mergeStatus(null, MediaPermissionStatus.denied),
        MediaPermissionStatus.denied,
      );
      expect(
        mergeStatus(MediaPermissionStatus.denied, MediaPermissionStatus.limited),
        MediaPermissionStatus.limited,
      );
    });
  });
}
