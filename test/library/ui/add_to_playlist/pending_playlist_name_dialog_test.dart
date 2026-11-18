import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_text_rules.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/pending_playlist_name_dialog.dart';
import 'package:material_ui/material_ui.dart';

import 'support/picker_host.dart';

class _Run {
  Future<String?>? result;
  bool done = false;
}

Future<_Run> _open(
  WidgetTester tester, {
  String initial = 'Playlist mới',
  String locale = 'vi',
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
    onOpen: (context) {
      run.result = showPendingPlaylistNameDialog(context, initialName: initial);
      run.result!.whenComplete(() => run.done = true);
    },
  );
  await openIt(tester);
  return run;
}

TextEditingController _controller(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!;

FilledButton _confirm(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  final l10n = l10nOf('vi');

  testWidgets(
    'shows title and field only (no description), prefilled and selected',
    (tester) async {
      await _open(tester, initial: 'Chill');
      expect(find.text(l10n.playlistCreateTitle), findsOneWidget);
      expect(find.textContaining('chỉ được tạo khi bấm Thêm'), findsNothing);
      final c = _controller(tester);
      expect(c.text, 'Chill');
      expect(c.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(find.text('5 / $playlistNameMaxLength'), findsOneWidget);
      expect(_confirm(tester).onPressed, isNotNull);
    },
  );

  testWidgets('empty and too long names show an error and block confirm', (
    tester,
  ) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(find.text(l10n.playlistNameEmpty), findsOneWidget);
    expect(_confirm(tester).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      'x' * (playlistNameMaxLength + 1),
    );
    await tester.pump();
    expect(find.text(l10n.playlistNameTooLong), findsOneWidget);
    expect(_confirm(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'ok');
    await tester.pump();
    expect(find.text(l10n.playlistNameTooLong), findsNothing);
    expect(_confirm(tester).onPressed, isNotNull);
  });

  testWidgets('confirm returns the cleaned name', (tester) async {
    final run = await _open(tester);
    await tester.enterText(find.byType(TextField), '  Đi biển  ');
    await tester.pump();
    await tester.tap(find.text(l10n.playlistPickerNewConfirm));
    await tester.pumpAndSettle();
    expect(await run.result, 'Đi biển');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Enter submits a valid name and ignores an invalid one', (
    tester,
  ) async {
    final run = await _open(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(run.done, isFalse, reason: 'empty name keeps the dialog open');

    await tester.enterText(find.byType(TextField), 'Gym');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(await run.result, 'Gym');
  });

  testWidgets('Huỷ and Esc resolve to null', (tester) async {
    var run = await _open(tester);
    await tester.tap(find.text(l10n.playlistCancel));
    await tester.pumpAndSettle();
    expect(await run.result, isNull);

    run = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await run.result, isNull);
    expect(find.byType(TextField), findsNothing);
  });

  group('layout', () {
    for (final (label, size, scale, brightness, reduce) in [
      ('phone 2.0 dark', phone, 2.0, Brightness.dark, false),
      ('desktop 1.5', desktop, 1.5, Brightness.light, false),
      ('desktop 2.0 animations off', desktop, 2.0, Brightness.light, true),
    ]) {
      testWidgets('long name and message fit ($label)', (tester) async {
        await _open(
          tester,
          initial: 'Một danh sách phát với cái tên dài ' * 4,
          size: size,
          textScale: scale,
          brightness: brightness,
          reduceMotion: reduce,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.playlistCreateTitle), findsOneWidget);
      });
    }
  });
}
