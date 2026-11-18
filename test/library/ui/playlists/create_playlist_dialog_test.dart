import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/playlists/dialogs/create_playlist_dialog.dart';
import 'package:material_ui/material_ui.dart';

import 'support/playlist_ui_harness.dart';

Finder _field() => find.byType(TextField);
Finder _create(String label) => find.widgetWithText(FilledButton, label);

Future<Future<String?>> _open(WidgetTester t, PlaylistUiHarness h) async {
  final result = h.launch(t, showCreatePlaylistDialog);
  await t.pumpAndSettle();
  return result;
}

void main() {
  uiTest('opens prefilled, selected and focused', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    await _open(t, h);

    final field = t.widget<TextField>(_field());
    expect(field.controller!.text, l10n.playlistDefaultName);
    expect(
      field.controller!.selection,
      TextSelection(
        baseOffset: 0,
        extentOffset: l10n.playlistDefaultName.length,
      ),
    );
    expect(
      t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    // The default name equals the title: look at the title widget only.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.data == l10n.playlistCreateTitle,
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.plScreensCharCount(12, 200)), findsOneWidget);
    expect(canTap(t, _create(l10n.playlistCreateConfirm)), isTrue);
  });

  uiTest('blank name: error under the field, Create disabled, Enter ignored', (
    t,
  ) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    await _open(t, h);

    await t.enterText(_field(), '  \t ');
    await t.pump();
    expect(find.text(l10n.playlistNameEmpty), findsOneWidget);
    expect(canTap(t, _create(l10n.playlistCreateConfirm)), isFalse);

    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(h.store.createCalls, 0);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  uiTest('control characters are not counted nor saved', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final result = await _open(t, h);
    await t.enterText(_field(), 'a\u0007b\u0000c');
    await t.pump();
    expect(find.text(l10n.plScreensCharCount(3, 200)), findsOneWidget);

    await t.tap(_create(l10n.playlistCreateConfirm));
    await eventually(t, () => h.store.createCalls == 1, what: 'create call');
    final uid = await t.runAsync(() => result);
    final stored = await storedPlaylists(t, h);
    expect(stored.single.name, 'abc');
    expect(stored.single.uid, uid);
  });

  uiTest('200 graphemes pass, 201 fail (emoji and combining marks)', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    await _open(t, h);
    // A family emoji and "e" + combining accent are one grapheme each.
    const unit = '\u{1F468}‍\u{1F469}‍\u{1F467}é';
    final ok = unit * 100; // 200 graphemes
    await t.enterText(_field(), ok);
    await t.pump();
    expect(find.text(l10n.plScreensCharCount(200, 200)), findsOneWidget);
    expect(find.text(l10n.playlistNameTooLong), findsNothing);
    expect(canTap(t, _create(l10n.playlistCreateConfirm)), isTrue);

    await t.enterText(_field(), '${ok}x');
    await t.pump();
    expect(find.text(l10n.plScreensCharCount(201, 200)), findsOneWidget);
    expect(find.text(l10n.playlistNameTooLong), findsOneWidget);
    expect(canTap(t, _create(l10n.playlistCreateConfirm)), isFalse);
  });

  uiTest('Enter creates the playlist and opens its page', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final result = await _open(t, h);
    await t.enterText(_field(), 'Road trip');
    await t.testTextInput.receiveAction(TextInputAction.done);
    final uid = (await _awaitResult(t, result))!;
    await t.pumpAndSettle();

    final stored = await storedPlaylists(t, h);
    expect(stored.map((p) => p.name), ['Road trip']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('PAGE $uid'), findsOneWidget);
  });

  uiTest('same name twice is allowed', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    for (var i = 0; i < 2; i++) {
      final result = await _open(t, h);
      await t.enterText(_field(), 'Mix');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await _awaitResult(t, result);
      await t.pumpAndSettle();
      h.router.pop();
      await t.pumpAndSettle();
    }
    expect((await storedPlaylists(t, h)).map((p) => p.name), ['Mix', 'Mix']);
  });

  uiTest('a second tap while saving creates one playlist', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    h.store.createGate = Completer<void>();
    final result = await _open(t, h);
    await t.tap(_create(l10n.playlistCreateConfirm));
    await t.pump();
    // Busy: the button shows progress (its label stays in semantics) and
    // neither button reacts.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      canTap(t, find.widgetWithText(TextButton, l10n.playlistCancel)),
      isFalse,
    );
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(h.store.createCalls, 1);

    h.store.createGate!.complete();
    await _awaitResult(t, result);
    await t.pumpAndSettle();
    expect(h.store.createCalls, 1);
    expect((await storedPlaylists(t, h)), hasLength(1));
  });

  uiTest('failure keeps the dialog, toasts, and a retry works', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    h.store.createError = StateError('disk full');
    final result = await _open(t, h);
    await t.tap(_create(l10n.playlistCreateConfirm));
    await eventually(
      t,
      () => find.text(l10n.playlistSaveFailed).evaluate().isNotEmpty,
      what: 'failure toast',
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(canTap(t, _create(l10n.playlistCreateConfirm)), isTrue);
    expect(await storedPlaylists(t, h), isEmpty);

    h.store.createError = null;
    await t.tap(_create(l10n.playlistCreateConfirm));
    await _awaitResult(t, result);
    await t.pumpAndSettle();
    expect(await storedPlaylists(t, h), hasLength(1));
  });

  uiTest('Cancel closes without writing', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final result = await _open(t, h);
    await t.tap(find.widgetWithText(TextButton, l10n.playlistCancel));
    await t.pumpAndSettle();
    expect(await result, isNull);
    expect(h.store.createCalls, 0);
    expect(find.text('PAGE x'), findsNothing);
  });

  uiTest('desktop, animations off: 440 dp dialog, Enter creates', (t) async {
    final h = await PlaylistUiHarness.pump(
      t,
      width: 1400,
      disableAnimations: true,
    );
    final result = await _open(t, h);
    expect(t.getSize(find.byType(AlertDialog)).width, 440);
    await t.enterText(_field(), 'Desk');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await _awaitResult(t, result);
    await t.pumpAndSettle();
    expect((await storedPlaylists(t, h)).single.name, 'Desk');
  });
}

/// Pumps until the dialog future [result] completes (the write is real
/// database work) and returns its value.
Future<String?> _awaitResult(WidgetTester t, Future<String?> result) async {
  var done = false;
  String? value;
  unawaited(
    result.then((v) {
      value = v;
      done = true;
    }),
  );
  await eventually(t, () => done, what: 'dialog result');
  return value;
}
