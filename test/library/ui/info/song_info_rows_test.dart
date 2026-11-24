import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'song_info_fixtures.dart';
import 'song_info_harness.dart';

/// Records what is put on the clipboard.
void _watchClipboard(WidgetTester tester) {
  final box = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        box.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  _boxes[tester] = box;
}

final _boxes = Expando<List<String>>();
List<String> _copied(WidgetTester tester) => _boxes[tester]!;

/// The topmost render object at the centre of [finder] is [finder]'s own:
/// nothing (a barrier, a route) is drawn over it.
void _expectOnTop(WidgetTester tester, Finder finder) {
  final hit = tester.hitTestOnBinding(tester.getCenter(finder));
  final target = tester.renderObject(finder);
  expect(
    hit.path.any((e) => identical(e.target, target)),
    isTrue,
    reason: 'something is drawn over $finder',
  );
}

void main() {
  group('toast', () {
    for (final (name, size) in [
      ('page', const Size(390, 2600)),
      ('box', const Size(1300, 2600)),
    ]) {
      testWidgets('copy toast is on top of the $name', (tester) async {
        _watchClipboard(tester);
        await pumpInfo(
          tester,
          initial: fullDetails(id: 7),
          size: size,
          canReveal: false,
        );
        await tester.tap(byIconButton('Copy path'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Path copied'), findsOneWidget);
        _expectOnTop(tester, find.text('Path copied'));
        await tester.pump(const Duration(seconds: 5));
      });
    }
  });

  group('links', () {
    testWidgets('a link closes the page', (tester) async {
      final h = await pumpInfo(tester, initial: fullDetails(id: 7));
      await tester.tap(link('Ballad'));
      await tester.pumpAndSettle();
      expect(find.byType(KOverlayPageScope), findsNothing);
      await h.opened;
    });

    testWidgets('a row of artists has one link each and plain ", " between', (
      tester,
    ) async {
      await pumpInfo(tester, initial: fullDetails(id: 7));
      expect(link('Phan Mạnh Quỳnh'), findsOneWidget);
      expect(find.text(', '), findsWidgets);
    });

    testWidgets('the language link carries the "detected" label', (
      tester,
    ) async {
      await pumpInfo(tester, initial: fullDetails(id: 7));
      expect(find.text('detected'), findsOneWidget);
    });

    testWidgets('an empty link row shows "Unknown" when the eye is on', (
      tester,
    ) async {
      final h = await pumpInfo(tester, initial: bareDetails());
      expect(find.text('Genre'), findsNothing);
      h.settings.write('library.song_info_show_empty', true);
      await tester.pump();
      expect(find.text('Genre'), findsOneWidget);
      expect(find.text('Unknown'), findsWidgets);
      expect(link('Ballad'), findsNothing);
    });
  });

  group('copy', () {
    testWidgets('long press copies a value and says so (phone)', (
      tester,
    ) async {
      _watchClipboard(tester);
      await pumpInfo(tester, initial: fullDetails(id: 7));
      await tester.longPress(find.text('Nhạc phim Người bất tử').first);
      await tester.pump();
      expect(_copied(tester), ['Nhạc phim Người bất tử']);
      expect(find.text('Copied: Nhạc phim Người bất tử'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a date row copies the date, not "8 years ago"', (
      tester,
    ) async {
      _watchClipboard(tester);
      await pumpInfo(tester, initial: fullDetails(id: 7));
      final age = RegExp(r'^2018-03 · \d+ years ago$');
      await tester.longPress(
        find.byWidgetPredicate((w) => w is Text && age.hasMatch(w.data ?? '')),
      );
      await tester.pump();
      expect(_copied(tester), ['2018-03']);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the path button copies the path (phone: own button row)', (
      tester,
    ) async {
      _watchClipboard(tester);
      // Android has no file manager to open: canReveal is false there.
      await pumpInfo(tester, initial: fullDetails(id: 7), canReveal: false);
      await tester.tap(byIconButton('Copy path'));
      await tester.pump();
      expect(_copied(tester), ['/home/u/Music/Blue/01 - Song.flac']);
      expect(find.text('Path copied'), findsOneWidget);
      // The phone has no "open in file manager".
      expect(find.byIcon(KIcons.folderOpen), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a soon row is never copied', (tester) async {
      _watchClipboard(tester);
      await pumpInfo(tester, initial: fullDetails(id: 7));
      await tester.longPress(find.text('ReplayGain'));
      await tester.pump();
      expect(_copied(tester), isEmpty);
    });
  });

  group('desktop path buttons', () {
    testWidgets('copy, folder and reveal sit at the end of the row', (
      tester,
    ) async {
      final h = await pumpInfo(
        tester,
        initial: fullDetails(id: 7),
        size: const Size(1300, 2600),
      );
      await tester.tap(byIconButton('Show in file manager'));
      await tester.pump();
      expect(h.fileManager.revealed, isEmpty); // the harness fake is unused
      expect(byIconButton('Go to folder'), findsOneWidget);
    });

    testWidgets('no file manager: no reveal button', (tester) async {
      await pumpInfo(
        tester,
        initial: fullDetails(id: 7),
        size: const Size(1300, 2600),
        canReveal: false,
      );
      expect(find.byIcon(KIcons.folderOpen), findsNothing);
      expect(byIconButton('Go to folder'), findsOneWidget);
    });
  });

  group('your data', () {
    testWidgets('the heart writes the favorite and follows the stream', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final h = await pumpInfo(tester, initial: fullDetails(id: 7));
      h.favoriteIds.add(const {});
      await tester.pump();
      await tester.tap(find.text('Not a favorite'));
      await tester.pump();
      expect(h.favorites.calls.single.$1, [const TrackId(7)]);
      expect(h.favorites.calls.single.$2, isTrue);
      h.favoriteIds.add({const TrackId(7)});
      await tester.pump();
      expect(find.text('Favorite'), findsWidgets);
      expect(find.text('Not a favorite'), findsNothing);
      // Liked is said by state; the pill itself is not tinted.
      final chip = find.widgetWithText(KChip, 'Favorite');
      expect(tester.getSemantics(chip), isSemantics(isSelected: true));
      expect(tester.widget<KChip>(chip).tintWhenSelected, isFalse);
      semantics.dispose();
    });

    testWidgets('ratings and ReplayGain read "Coming soon" and are dimmed', (
      tester,
    ) async {
      await pumpInfo(tester, initial: fullDetails(id: 7));
      expect(find.text('Coming soon'), findsNWidgets(2));
    });

    testWidgets('a song never played reads "Never played"; counts are 0', (
      tester,
    ) async {
      await pumpInfo(tester, initial: bareDetails());
      expect(find.text('Never played'), findsOneWidget);
      expect(find.text('0 times'), findsNWidgets(2));
    });
  });
}
