import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/custom_covers_store.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/playlists/dialogs/duplicate_playlist_dialog.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/playlist_ui_harness.dart';

Finder _field() => find.byType(TextField);
Finder _confirm(String label) => find.widgetWithText(FilledButton, label);

/// Opens the dialog for [source] and returns the future of its result.
Future<Future<String?>> _open(
  WidgetTester t,
  PlaylistUiHarness h,
  PlaylistSummary source,
) async {
  final result = h.launch(t, (c) => showDuplicatePlaylistDialog(c, source));
  await t.pumpAndSettle();
  return result;
}

Future<String?> _await(WidgetTester t, Future<String?> result) async {
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

Future<String?> _coverKeyOf(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
) async {
  final key = await t.runAsync<String?>(
    () => customCoverKey(h.fixture.db, 'playlist', uid),
  );
  return key;
}

void main() {
  uiTest('prefilled "<name> (copy)", selected, focused', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);

    final controller = t.widget<TextField>(_field()).controller!;
    expect(controller.text, l10n.playlistCopyName('Src'));
    expect(controller.selection.extentOffset, controller.text.length);
    expect(controller.selection.baseOffset, 0);
    expect(
      t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(find.text(l10n.plScreensDuplicateConfirm), findsOneWidget);
  });

  uiTest('a 200-character name keeps its " (copy)" suffix within 200', (
    t,
  ) async {
    final h = await PlaylistUiHarness.pump(t);
    final src = await seedPlaylist(t, h, name: 'x' * 200);
    await _open(t, h, src);
    final text = t.widget<TextField>(_field()).controller!.text;
    expect(text.characters.length, 200);
    expect(text, endsWith(' (copy)'));
  });

  uiTest('no custom cover: no switch row, copy has no cover', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    final result = await _open(t, h, src);
    expect(find.text(l10n.plScreensDuplicateCopyCover), findsNothing);

    await t.tap(_confirm(l10n.plScreensDuplicateConfirm));
    final copy = (await _await(t, result))!;
    expect(copy, isNot(src.uid));
    expect(await _coverKeyOf(t, h, copy), isNull);
  });

  uiTest('custom cover: row starts off; off leaves the copy uncovered', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await h.giveCustomCover(t, src.uid);
    final result = await _open(t, h, src);
    await eventually(
      t,
      () => find.text(l10n.plScreensDuplicateCopyCover).evaluate().isNotEmpty,
      what: 'copy-cover row',
    );
    expect(toggled(t, find.byType(KSwitch)), isFalse);

    await t.tap(_confirm(l10n.plScreensDuplicateConfirm));
    final copy = (await _await(t, result))!;
    expect(await _coverKeyOf(t, h, copy), isNull);
    handle.dispose();
  });

  uiTest('custom cover: tapping the row turns it on; the copy shares it', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await h.giveCustomCover(t, src.uid);
    final result = await _open(t, h, src);
    await eventually(
      t,
      () => find.text(l10n.plScreensDuplicateCopyCover).evaluate().isNotEmpty,
      what: 'copy-cover row',
    );
    // The whole row is the target, not only the switch.
    await t.tap(find.text(l10n.plScreensDuplicateCopyCover));
    await t.pump();
    expect(toggled(t, find.byType(KSwitch)), isTrue);
    expect(t.getSize(find.byType(KSwitchRow)).height, greaterThanOrEqualTo(48));

    await t.tap(_confirm(l10n.plScreensDuplicateConfirm));
    final copy = (await _await(t, result))!;
    expect(await _coverKeyOf(t, h, copy), 'ab/cover-key');
    handle.dispose();
  });

  uiTest('copy toast names the copy and no navigation happens', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    final result = await _open(t, h, src);
    await t.enterText(_field(), 'Party');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await _await(t, result);
    await t.pumpAndSettle();

    expect(find.text(l10n.playlistDuplicated('Party')), findsOneWidget);
    expect(h.router.state.uri.path, '/');
    final stored = await storedPlaylists(t, h);
    expect(stored.map((p) => p.name), containsAll(['Src', 'Party']));
  });

  uiTest('blank name disables Duplicate and Enter does nothing', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.enterText(_field(), '   ');
    await t.pump();
    expect(find.text(l10n.playlistNameEmpty), findsOneWidget);
    expect(canTap(t, _confirm(l10n.plScreensDuplicateConfirm)), isFalse);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(h.store.duplicateCalls, 0);
  });

  uiTest('playlist gone: closes with the not-in-library toast', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    final result = await _open(t, h, src);
    await t.runAsync(() => h.fixture.repo.deletePlaylist(src.uid));
    await t.tap(_confirm(l10n.plScreensDuplicateConfirm));
    expect(await _await(t, result), isNull);
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l10n.libraryNotFoundMessage), findsOneWidget);
    expect(await storedPlaylists(t, h), isEmpty);
  });

  uiTest('failure keeps the dialog and toasts', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    h.store.duplicateError = StateError('boom');
    await _open(t, h, src);
    await t.tap(_confirm(l10n.plScreensDuplicateConfirm));
    await eventually(
      t,
      () => find.text(l10n.playlistSaveFailed).evaluate().isNotEmpty,
      what: 'failure toast',
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(await storedPlaylists(t, h), hasLength(1));
  });

  uiTest('double tap makes one copy', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    final result = await _open(t, h, src);
    await t.tap(_confirm(l10n.plScreensDuplicateConfirm));
    await t.tap(_confirm(l10n.plScreensDuplicateConfirm), warnIfMissed: false);
    await _await(t, result);
    await t.pumpAndSettle();
    expect(h.store.duplicateCalls, 1);
    expect(await storedPlaylists(t, h), hasLength(2));
  });

  uiTest('copy keeps order and repeats of the source', (t) async {
    final h = await PlaylistUiHarness.pump(t, width: 1400);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h, trackCount: 3);
    final result = await _open(t, h, src);
    await t.tap(_confirm(l10n.plScreensDuplicateConfirm));
    final copy = (await _await(t, result))!;
    final original = await t.runAsync(() => h.fixture.liveTracks(src.uid));
    expect(await t.runAsync(() => h.fixture.liveTracks(copy)), original);
  });
}
