import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
import 'package:kanaru/src/library/ui/info/song_info_hero.dart';
import 'package:kanaru/src/library/ui/info/song_info_skeleton.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'song_info_fixtures.dart';
import 'song_info_harness.dart';

Finder get _page => find.byType(KOverlayPageScope);

void main() {
  group('loading, gone and error', () {
    testWidgets('loading shows six bars; with animations off nothing runs', (
      tester,
    ) async {
      await pumpInfo(tester, still: true);
      expect(find.byType(SongInfoSkeleton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SongInfoSkeleton),
          matching: find.byType(DecoratedBox),
        ),
        findsNWidgets(SongInfoSkeleton.bars),
      );
      // A pulse that never stopped would time pumpAndSettle out.
      await tester.pumpAndSettle();
      // The eye is dimmed until the details are there.
      expect(
        iconButtonAround(tester, find.byIcon(KIcons.eye)).enabled,
        isFalse,
      );
    });

    testWidgets('a song that is gone says so and Back closes the page', (
      tester,
    ) async {
      final h = await pumpInfo(tester);
      h.details.add(null);
      await tester.pump();
      expect(find.text('This is no longer in your library.'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(_page, findsNothing);
      await h.opened;
    });

    testWidgets('a read error shows the load-failed message', (tester) async {
      final h = await pumpInfo(tester);
      h.details.addError(StateError('boom'));
      await tester.pump();
      expect(find.text('Could not read the song info'), findsOneWidget);
      // The mockup draws no Back button for a failed read.
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('a song that goes away while open turns into the message', (
      tester,
    ) async {
      final h = await pumpInfo(tester, initial: fullDetails(id: 7));
      expect(find.text('Ballad'), findsOneWidget);
      h.details.add(null);
      await tester.pump();
      expect(find.text('Ballad'), findsNothing);
      expect(find.text('This is no longer in your library.'), findsOneWidget);
    });
  });

  group('a full song', () {
    testWidgets('page: bar title, hero first, groups in order', (tester) async {
      await pumpInfo(tester, initial: fullDetails(id: 7));
      expect(find.text('Song info'), findsWidgets);
      expect(find.byType(SongInfoHero), findsOneWidget);
      for (final t in ['Tags', 'Audio', 'File', 'Yours']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.text('Ngày chưa giông bão'), findsWidgets);
      expect(link('Bùi Lan Hương'), findsNWidgets(2)); // artist + album artist
      expect(link('Phan Mạnh Quỳnh'), findsOneWidget);
      expect(link('Ballad'), findsOneWidget);
      // No edit button anywhere.
      expect(find.byIcon(KIcons.edit), findsNothing);
    });

    testWidgets('a wide window shows a box with the hero in its head', (
      tester,
    ) async {
      await pumpInfo(
        tester,
        initial: fullDetails(id: 7),
        size: const Size(800, 2600),
      );
      final scope = tester.widget<KOverlayPageScope>(_page);
      expect(scope.kind, KOverlayKind.box);
      expect(find.byType(SongInfoHero), findsOneWidget);
    });

    testWidgets('a section from the registry sits right after Tags', (
      tester,
    ) async {
      final h = await pumpInfo(tester, openIt: false);
      h.registry.addSongDetailSection(
        SongDetailSection(
          id: 'lyrics',
          order: 1,
          build: (_, id) => Text('section for $id'),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      h.details.add(fullDetails(id: 7));
      await tester.pump(const Duration(milliseconds: 300));
      final section = tester.getTopLeft(find.text('section for 7')).dy;
      expect(section, greaterThan(tester.getTopLeft(find.text('Tags')).dy));
      expect(section, lessThan(tester.getTopLeft(find.text('Audio')).dy));
    });

    testWidgets('200 % text does not overflow', (tester) async {
      await pumpInfo(tester, initial: fullDetails(id: 7), textScale: 2);
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('empty fields and the eye', () {
    testWidgets('hidden by default, shown on toggle, remembered', (
      tester,
    ) async {
      final h = await pumpInfo(tester, initial: bareDetails());
      expect(find.text('Composer'), findsNothing);
      expect(find.text('Unknown'), findsNothing);
      final eye = byIconButton('Show 19 empty fields');
      expect(eye, findsOneWidget);
      await tester.tap(eye);
      await tester.pump();
      expect(find.text('Composer'), findsOneWidget);
      expect(find.text('Unknown'), findsWidgets);
      expect(byIconButton('Hide empty fields'), findsOneWidget);
      expect(h.settings.read('library.song_info_show_empty'), isTrue);
    });

    testWidgets('a full song has nothing to show: the eye is dimmed', (
      tester,
    ) async {
      await pumpInfo(tester, initial: fullDetails(id: 7));
      final eye = iconButtonAround(tester, find.byIcon(KIcons.eye));
      expect(eye.enabled, isFalse);
      expect(eye.tooltip, 'No empty fields');
    });
  });

  group('notices', () {
    testWidgets('a file with no tags says so', (tester) async {
      await pumpInfo(tester, initial: bareDetails());
      expect(find.text('This file has almost no tags'), findsOneWidget);
      expect(find.textContaining('Edit tags in the song menu'), findsOneWidget);
    });

    testWidgets('a tag read error', (tester) async {
      await pumpInfo(
        tester,
        initial: fullDetails(id: 7, scanError: 'bad frame'),
      );
      expect(find.text('Tags could not be read'), findsOneWidget);
      // The reader's own message is not shown to the user.
      expect(find.textContaining('bad frame'), findsNothing);
      expect(find.textContaining('damaged'), findsOneWidget);
    });

    testWidgets(
      'a missing file: notice, struck path, folder buttons dimmed, copy works',
      (tester) async {
        final h = await pumpInfo(
          tester,
          initial: fullDetails(
            id: 7,
            status: SongFileStatus.missing,
            missingSince: DateTime(2026, 11, 12, 8, 30).millisecondsSinceEpoch,
          ),
          size: const Size(1300, 2600),
        );
        expect(find.text('File not found'), findsNWidgets(2)); // notice + path
        expect(find.textContaining('Missing since'), findsOneWidget);
        final path = tester.widget<SelectableText>(
          find.byWidgetPredicate(
            (w) => w is SelectableText && w.data!.endsWith('01 - Song.flac'),
          ),
        );
        expect(path.style!.decoration, TextDecoration.lineThrough);
        expect(
          iconButtonAround(tester, find.byIcon(KIcons.folders)).enabled,
          isFalse,
        );
        expect(
          iconButtonAround(tester, find.byIcon(KIcons.folderOpen)).enabled,
          isFalse,
        );
        expect(
          iconButtonAround(tester, find.byIcon(KIcons.copy).first).enabled,
          isTrue,
        );
        expect(h.fileManager.revealed, isEmpty);
      },
    );

    testWidgets('the file goes missing while the page is open', (tester) async {
      final h = await pumpInfo(tester, initial: fullDetails(id: 7));
      expect(find.text('File not found'), findsNothing);
      h.details.add(
        fullDetails(id: 7, status: SongFileStatus.missing, missingSince: 5),
      );
      await tester.pump();
      expect(find.text('File not found'), findsNWidgets(2));
    });
  });

  testWidgets('Esc closes the page', (tester) async {
    final h = await pumpInfo(tester, initial: fullDetails(id: 7));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_page, findsNothing);
    await h.opened;
  });
}
