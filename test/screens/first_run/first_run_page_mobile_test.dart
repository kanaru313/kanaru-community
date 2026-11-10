import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/scan_folders.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/platform/data/permissions/android_media_permissions.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'support/first_run_host.dart';

const _none = MediaPermissionStatus.denied;
const _ok = MediaPermissionStatus.granted;
const _music = '/storage/emulated/0/Music';

MediaPermissionState _p(
  MediaPermissionStatus audio,
  MediaPermissionStatus images,
) => perms(audio, images);

FakeCatalog _androidCatalog({
  bool withSuggestion = false,
}) => FakeCatalog(android: true)
  ..suggestion = withSuggestion ? _music : null
  ..folders = const [
    AudioFolderSummary(path: _music, audioCount: 10),
    AudioFolderSummary(path: '$_music/Rock', audioCount: 4),
    AudioFolderSummary(path: '$_music/Ringtones', audioCount: 3),
    AudioFolderSummary(path: '/storage/emulated/0/Download', audioCount: 18),
    AudioFolderSummary(path: '/storage/emulated/0/Telegram', audioCount: 41),
  ];

/// The app goes to the background and comes back, step by step as the
/// platform reports it.
void _leaveAndReturn(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

SetupNextButton _next(WidgetTester tester) =>
    tester.widget<SetupNextButton>(find.byType(SetupNextButton));

void main() {
  group('permissions', () {
    testWidgets('none granted: both rows open, "Allow", the note', (
      tester,
    ) async {
      await pumpFirstRun(tester, android: true);
      expect(find.text('Permissions'), findsOneWidget);
      expect(find.text('Music and audio'), findsOneWidget);
      expect(find.text('Photos and videos'), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);
      expect(
        find.text(
          'Both are needed to continue. Kanaru does not ask for “All files '
          'access”.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(KIcons.check), findsNothing);
    });

    testWidgets('only music granted: one check and "Allow the missing '
        'permission"', (tester) async {
      await pumpFirstRun(tester, android: true, permission: _p(_ok, _none));
      expect(find.text('Allow the missing permission'), findsOneWidget);
      expect(find.byIcon(KIcons.check), findsOneWidget);
    });

    testWidgets('both granted: collapses to one line', (tester) async {
      await pumpFirstRun(tester, android: true, permission: _p(_ok, _ok));
      expect(
        find.text(
          'All permissions allowed · Music and audio · Photos and videos',
        ),
        findsOneWidget,
      );
      expect(find.text('Allow'), findsNothing);
    });

    testWidgets('blocked for good: "Open app settings" and how to turn them '
        'on', (tester) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(MediaPermissionStatus.permanentlyDenied, _none),
      );
      expect(find.text('Open app settings'), findsOneWidget);
      expect(find.textContaining('Settings › Apps › Kanaru'), findsOneWidget);
      await tester.tap(find.text('Open app settings'));
      await tester.pumpAndSettle();
      expect(h.fake.settingsOpened, 1);
    });

    testWidgets('"Allow" asks for music, then photos at once', (tester) async {
      final permissions = FakePermissions(_p(_none, _none))
        ..onAudio = ((s) => _p(_ok, s.images))
        ..onImages = ((s) => _p(s.audio, _ok));
      final h = await pumpFirstRun(
        tester,
        android: true,
        permissions: permissions,
      );
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(h.fake.requests, ['audio', 'images']);
      expect(find.text('Allow'), findsNothing);
      expect(
        find.text(
          'All permissions allowed · Music and audio · Photos and videos',
        ),
        findsOneWidget,
      );
    });

    testWidgets('music denied once explains why; photos are not asked', (
      tester,
    ) async {
      final h = await pumpFirstRun(tester, android: true);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(h.fake.requests, ['audio']);
      expect(
        find.text('Music permission is needed to find songs on the device.'),
        findsOneWidget,
      );
      expect(find.text('Allow'), findsOneWidget);
    });

    testWidgets('"only some photos" is not granted and says what to do', (
      tester,
    ) async {
      final permissions = FakePermissions(_p(_ok, _none))
        ..onImages = ((s) => _p(s.audio, MediaPermissionStatus.limited));
      await pumpFirstRun(tester, android: true, permissions: permissions);
      await tester.tap(find.text('Allow the missing permission'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Choosing only some photos cannot read cover.jpg: choose “Allow '
          'all”.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(KIcons.check), findsOneWidget);
      expect(find.text('Allow the missing permission'), findsOneWidget);
    });

    testWidgets('a permanent denial survives the check when the app comes '
        'back', (tester) async {
      // The plugin reports a permanent denial as plain "denied" when read.
      final real = AndroidMediaPermissions(
        sdkInt: () async => 34,
        readStatus: (_) async => PermissionStatus.denied,
        requestPermission: (_) async => PermissionStatus.permanentlyDenied,
      );
      await pumpFirstRun(tester, android: true, permissions: real);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(find.text('Open app settings'), findsOneWidget);

      _leaveAndReturn(tester);
      await tester.pumpAndSettle();
      expect(find.text('Open app settings'), findsOneWidget);
      expect(find.text('Allow'), findsNothing);
    });

    testWidgets('permissions granted in the settings show up on return', (
      tester,
    ) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(MediaPermissionStatus.permanentlyDenied, _none),
      );
      h.fake.state = _p(_ok, _ok);
      _leaveAndReturn(tester);
      await tester.pumpAndSettle();
      expect(find.text('Open app settings'), findsNothing);
      expect(find.textContaining('All permissions allowed'), findsOneWidget);
    });
  });

  group('folders', () {
    testWidgets('without music permission only the note is shown', (
      tester,
    ) async {
      await pumpFirstRun(
        tester,
        android: true,
        catalog: _androidCatalog(withSuggestion: true),
      );
      expect(
        find.text('Allow music access to see the folders that have music.'),
        findsNWidgets(2),
      );
      expect(find.text('Add folder'), findsNothing);
      expect(find.text('Add excluded folder'), findsNothing);
    });

    testWidgets('the arrow stays hidden until both permissions and a folder '
        'exist', (tester) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: _androidCatalog(),
      );
      expect(_next(tester).visible, isFalse);

      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();
      expect(_next(tester).visible, isTrue);
      expect(_next(tester).onPressed, isNotNull);
    });

    testWidgets('the arrow stays hidden with a folder but a missing photo '
        'permission', (tester) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _none),
        catalog: _androidCatalog(),
      );
      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();
      expect(_next(tester).visible, isFalse);
    });

    testWidgets('defaults: Music is chosen and its ringtone folder excluded, '
        'with an estimate', (tester) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: _androidCatalog(withSuggestion: true),
      );
      expect(find.text('Internal storage › Music'), findsOneWidget);
      expect(find.text('Internal storage › Music › Ringtones'), findsOneWidget);
      expect(
        find.text('Kanaru scans these folders · about 14 songs'),
        findsOneWidget,
      );
      expect(find.text('14 songs'), findsOneWidget);
      expect(find.text('3 songs'), findsOneWidget);
      expect(await liveScanFolders(h.db), hasLength(1));
      expect(h.fake.requests, isEmpty);
    });

    testWidgets('defaults wait for the music permission', (tester) async {
      final permissions = FakePermissions(_p(_none, _none))
        ..onAudio = ((s) => _p(_ok, s.images))
        ..onImages = ((s) => _p(s.audio, _ok));
      final h = await pumpFirstRun(
        tester,
        android: true,
        permissions: permissions,
        catalog: _androidCatalog(withSuggestion: true),
      );
      expect(await liveScanFolders(h.db), isEmpty);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(await liveScanFolders(h.db), hasLength(1));
      expect(find.text('Internal storage › Music'), findsOneWidget);
    });

    testWidgets('the add sheet lists folders that can be added and adds the '
        'chosen ones', (tester) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: _androidCatalog(),
      );
      await tester.tap(find.text('Add folder'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Add music folders'), findsOneWidget);
      expect(
        find.text('Folders with music that Android found.'),
        findsOneWidget,
      );
      expect(
        find.text('Internal storage › Download · 18 songs'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.tap(find.text('Download'));
      await tester.tap(find.text('Telegram'));
      await tester.pump();
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(await liveScanFolders(h.db), hasLength(2));
      expect(find.text('Internal storage › Download'), findsOneWidget);
      expect(find.text('Internal storage › Telegram'), findsOneWidget);
    });

    testWidgets('cancelling the sheet adds nothing', (tester) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: _androidCatalog(),
      );
      await tester.tap(find.text('Add folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await liveScanFolders(h.db), isEmpty);
    });

    testWidgets('the exclusion sheet lists only sub-folders of chosen '
        'folders', (tester) async {
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: _androidCatalog(),
      );
      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add excluded folder'));
      await tester.pumpAndSettle();
      expect(find.text('Exclude folders'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Ringtones'), findsOneWidget);
      expect(find.text('Download'), findsNothing);

      await tester.tap(find.text('Ringtones'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(find.text('Internal storage › Music › Ringtones'), findsOneWidget);
      expect(find.text('No folder excluded.'), findsNothing);
    });

    testWidgets('a removed Music folder can be added again from the sheet', (
      tester,
    ) async {
      final catalog = FakeCatalog(android: true)
        ..folders = const [
          AudioFolderSummary(path: '$_music/A', audioCount: 1),
          AudioFolderSummary(path: '$_music/B', audioCount: 1),
        ];
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: catalog,
      );
      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Music'));
      await tester.pumpAndSettle();
      expect(await liveScanFolders(h.db), isEmpty);

      await tester.tap(find.text('Add folder'));
      await tester.pumpAndSettle();
      expect(find.text('Internal storage › Music · 2 songs'), findsOneWidget);
      await tester.tap(find.text('Music'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(await liveScanFolders(h.db), hasLength(1));
    });

    testWidgets('picking a child and then its parent adds just the parent', (
      tester,
    ) async {
      final catalog = FakeCatalog(
        android: true,
      )..folders = const [AudioFolderSummary(path: '$_music/A', audioCount: 1)];
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: catalog,
      );
      await tester.tap(find.text('Add folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A'));
      await tester.tap(find.text('Music'));
      await tester.pump();
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();
      final folders = await liveScanFolders(h.db);
      expect([for (final f in folders) f.root], [_music]);
      expect(find.textContaining('already inside'), findsNothing);
      expect(find.textContaining('contains'), findsNothing);
    });

    testWidgets('MediaStore is read once for all the lists', (tester) async {
      final catalog = _androidCatalog(withSuggestion: true);
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: catalog,
      );
      await h.editor.excludeFolder(
        (await h.container.read(musicFoldersProvider.future)).single,
        '$_music/Rock',
        fromCatalog: true,
      );
      await tester.pumpAndSettle();
      // One shared read for the lists, one for the defaults.
      expect(catalog.audioFolderReads, lessThanOrEqualTo(2));
    });

    testWidgets('the sheet says when every folder is already chosen', (
      tester,
    ) async {
      final catalog = FakeCatalog(android: true)
        ..folders = const [AudioFolderSummary(path: _music, audioCount: 10)];
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _p(_ok, _ok),
        catalog: catalog,
      );
      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add folder'));
      await tester.pumpAndSettle();
      expect(
        find.text('Every folder with music is already chosen.'),
        findsOneWidget,
      );
    });

    testWidgets('theme opens a bottom sheet on a phone', (tester) async {
      await pumpFirstRun(tester, android: true, width: 400);
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
