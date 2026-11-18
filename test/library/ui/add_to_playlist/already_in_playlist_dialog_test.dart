import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/already_in_playlist_dialog.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist_model.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/picker_host.dart';

class _Run {
  Future<DuplicatePolicy?>? result;
}

const _one = [(uid: 'a', name: 'Chill', has: 2)];
const _many = [
  (uid: 'a', name: 'Chill', has: 2),
  (uid: 'b', name: 'Rock', has: 1),
];

Future<_Run> _open(
  WidgetTester tester,
  List<AffectedPlaylist> affected, {
  String locale = 'en',
  Size size = phone,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
}) async {
  final run = _Run();
  await pumpOpener(
    tester,
    locale: locale,
    size: size,
    textScale: textScale,
    brightness: brightness,
    reduceMotion: reduceMotion,
    onOpen: (context) =>
        run.result = showAlreadyInPlaylistDialog(context, affected: affected),
  );
  await openIt(tester);
  return run;
}

Finder _row(String text) => find.widgetWithText(SelectionRow, text);

void main() {
  final l10n = l10nOf('en');

  testWidgets('one playlist: its name and count, three text rows, first '
      'preselected', (tester) async {
    await _open(tester, _one);
    expect(find.text(l10n.playlistAlreadyTitle), findsOneWidget);
    expect(find.text(l10n.plAddAlreadyInOne(2, 'Chill')), findsOneWidget);
    expect(find.text(l10n.playlistAlreadyAppliesToAll), findsNothing);
    expect(find.byType(SelectionRow), findsNWidgets(3));
    expect(find.text(l10n.playlistAlreadySkipHint(2)), findsOneWidget);
    expect(find.text(l10n.playlistAlreadyAllHint(2)), findsOneWidget);

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(_row(l10n.playlistAlreadySkip)),
      isSemantics(isSelected: true, isEnabled: true, hasEnabledState: true),
    );
    expect(
      tester.getSemantics(_row(l10n.playlistAlreadyAll)),
      isSemantics(isSelected: false, isEnabled: true, hasEnabledState: true),
    );
    handle.dispose();
    expect(find.text(l10n.playlistCancel), findsOneWidget);
    expect(find.text(l10n.playlistConfirm), findsOneWidget);
  });

  testWidgets('several playlists: one count line, applies to all', (
    tester,
  ) async {
    await _open(tester, _many);
    expect(find.text(l10n.plAddAlreadyInMany(2)), findsNothing);
    expect(
      find.text(
        '${l10n.plAddAlreadyInMany(2)} ${l10n.playlistAlreadyAppliesToAll}',
      ),
      findsOneWidget,
    );
    // The held songs add up over the playlists.
    expect(find.text(l10n.playlistAlreadySkipHint(3)), findsOneWidget);
  });

  testWidgets('Confirm returns the preselected policy', (tester) async {
    final run = await _open(tester, _one);
    await tester.tap(find.text(l10n.playlistConfirm));
    await tester.pumpAndSettle();
    expect(await run.result, DuplicatePolicy.skipExisting);
  });

  testWidgets('a tap only selects; Confirm returns the chosen policy', (
    tester,
  ) async {
    final run = await _open(tester, _one);
    await tester.tap(find.text(l10n.playlistAlreadyMove));
    await tester.pumpAndSettle();
    expect(find.text(l10n.playlistAlreadyTitle), findsOneWidget);
    await tester.tap(find.text(l10n.playlistConfirm));
    await tester.pumpAndSettle();
    expect(await run.result, DuplicatePolicy.moveToEnd);

    final again = await _open(tester, _one);
    await tester.tap(find.text(l10n.playlistAlreadyAll));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.playlistConfirm));
    await tester.pumpAndSettle();
    expect(await again.result, DuplicatePolicy.addAll);
  });

  testWidgets('Huỷ and Esc resolve to null', (tester) async {
    var run = await _open(tester, _one);
    await tester.tap(find.text(l10n.playlistAlreadyAll));
    await tester.pump();
    await tester.tap(find.text(l10n.playlistCancel));
    await tester.pumpAndSettle();
    expect(await run.result, isNull);

    run = await _open(tester, _one);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await run.result, isNull);
    expect(find.text(l10n.playlistAlreadyTitle), findsNothing);
  });

  testWidgets('is a centred dialog on the phone too, not a sheet', (
    tester,
  ) async {
    await _open(tester, _one);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  group('layout', () {
    for (final (label, locale, size, scale, brightness, reduce) in [
      ('phone 2.0 vi dark', 'vi', phone, 2.0, Brightness.dark, false),
      ('desktop 1.5 vi', 'vi', desktop, 1.5, Brightness.light, false),
      (
        'desktop 2.0 animations off',
        'en',
        desktop,
        2.0,
        Brightness.light,
        true,
      ),
    ]) {
      testWidgets('long playlist name fits ($label)', (tester) async {
        await _open(
          tester,
          [
            (
              uid: 'a',
              name: 'Những bản nhạc buồn nhất mọi thời đại ' * 3,
              has: 2,
            ),
          ],
          locale: locale,
          size: size,
          textScale: scale,
          brightness: brightness,
          reduceMotion: reduce,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(SelectionRow), findsWidgets);
      });
    }
  });
}
