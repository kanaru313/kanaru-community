import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/screens/first_run/ui/exclusions_section.dart';
import 'package:kanaru/src/screens/first_run/ui/library_tabs_section.dart';
import 'package:kanaru/src/screens/first_run/ui/music_folders_section.dart';
import 'package:kanaru/src/screens/first_run/ui/no_music_card_note.dart';
import 'package:kanaru/src/screens/first_run/ui/setup_mode.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/first_run_host.dart';

const _music = '/storage/emulated/0/Music';
final _granted = perms(
  MediaPermissionStatus.granted,
  MediaPermissionStatus.granted,
);

/// The three folder blocks in [mode] inside a tree whose tickers the test
/// switches, as a page kept mounted behind another tab is.
class _Blocks extends StatelessWidget {
  const _Blocks({required this.shown, required this.mode});

  final ValueListenable<bool> shown;
  final SetupMode mode;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: shown,
    builder: (_, visible, _) => TickerMode(
      enabled: visible,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              MusicFoldersSection(mode: mode),
              ExclusionsSection(mode: mode),
              LibraryTabsSection(mode: mode),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('first run keeps its captions visible', () {
    testWidgets('no ⓘ anywhere on the page', (tester) async {
      await pumpFirstRun(tester);
      expect(find.byType(KHelpIcon), findsNothing);
      expect(
        find.text('Kanaru scans these folders and everything inside them.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Turn on the tabs you want, drag to reorder. '
          'At least one tab stays on.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the Android page has no ⓘ either', (tester) async {
      await pumpFirstRun(tester, android: true, permission: _granted);
      expect(find.byType(KHelpIcon), findsNothing);
    });
  });

  group('settings mode', () {
    testWidgets('a section note moves behind the ⓘ', (tester) async {
      await pumpFirstRun(
        tester,
        child: _Blocks(shown: ValueNotifier(true), mode: SetupMode.settings),
      );
      expect(find.byType(KHelpIcon), findsNWidgets(3));
      expect(
        find.text('Kanaru scans these folders and everything inside them.'),
        findsNothing,
      );
    });

    testWidgets('the state line stays visible: music permission missing', (
      tester,
    ) async {
      await pumpFirstRun(
        tester,
        android: true,
        permission: perms(
          MediaPermissionStatus.denied,
          MediaPermissionStatus.denied,
        ),
        child: _Blocks(shown: ValueNotifier(true), mode: SetupMode.settings),
      );
      expect(
        find.text('Allow music access to see the folders that have music.'),
        findsNWidgets(2),
      );
    });
  });

  group('a page that is not shown', () {
    testWidgets('does not read MediaStore again after a folder edit', (
      tester,
    ) async {
      final shown = ValueNotifier(true);
      addTearDown(shown.dispose);
      final catalog = FakeCatalog(android: true)
        ..folders = const [AudioFolderSummary(path: _music, audioCount: 10)];
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _granted,
        catalog: catalog,
        child: _Blocks(shown: shown, mode: SetupMode.settings),
      );
      await frames(tester);
      final reads = catalog.audioFolderReads;
      expect(reads, greaterThan(0));

      shown.value = false;
      await frames(tester);
      await h.editor.addFolder(_music, fromCatalog: true);
      await frames(tester);
      expect(catalog.audioFolderReads, reads);
      expect(catalog.refreshCalls, 0);

      // Shown again: the page catches up with the edit.
      shown.value = true;
      await frames(tester);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('10 songs'), findsWidgets);
    });

    testWidgets('the no-music note starts nothing while hidden', (
      tester,
    ) async {
      final shown = ValueNotifier(false);
      addTearDown(shown.dispose);
      final catalog = FakeCatalog(android: true)
        ..result = const AudioFoldersListed([]);
      await pumpFirstRun(
        tester,
        android: true,
        permission: _granted,
        catalog: catalog,
        child: ValueListenableBuilder<bool>(
          valueListenable: shown,
          builder: (_, visible, _) => TickerMode(
            enabled: visible,
            child: const Scaffold(
              body: NoMusicCardNote(autoRun: true, seenFrom: 0),
            ),
          ),
        ),
      );
      await frames(tester);
      expect(catalog.audioFolderReads, 0);
      expect(catalog.refreshCalls, 0);
      expect(find.text('No folder chosen yet.'), findsOneWidget);

      // Shown: it reads the index and runs its one refresh.
      shown.value = true;
      await frames(tester, 6);
      expect(catalog.audioFolderReads, greaterThan(0));
      expect(catalog.refreshCalls, 1);
    });
  });
}
