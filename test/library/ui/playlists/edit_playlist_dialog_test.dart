import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/custom_covers_store.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/ui/playlist_common/playlist_cover.dart';
import 'package:kanaru/src/library/ui/playlists/dialogs/edit_playlist_dialog.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'support/playlist_ui_harness.dart';

Finder _name() => find.byType(TextField).at(0);
Finder _description() => find.byType(TextField).at(1);

/// The Save button of either shell (text button on mobile, filled on
/// desktop).
Finder _save(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

class _FailingCovers implements CustomCoverController {
  @override
  Future<void> removeCover(CustomCoverKind kind, String itemKey) =>
      Future.error(const FileSystemException('disk gone'));

  @override
  Future<void> importCover(CustomCoverKind kind, String itemKey, File source) =>
      Future.error(const FileSystemException('disk gone'));

  @override
  Future<int> collectUnreferencedFiles() async => 0;
}

Future<void> _open(
  WidgetTester t,
  PlaylistUiHarness h,
  PlaylistSummary summary,
) async {
  unawaited(h.launch(t, (c) => showEditPlaylistDialog(c, summary)));
  await t.pumpAndSettle();
}

Future<PlaylistSummary> _stored(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
) async => (await storedPlaylists(t, h)).singleWhere((p) => p.uid == uid);

Future<void> _tapSave(WidgetTester t, PlaylistUiHarness h) async {
  await t.tap(_save(h.l10n(t).playlistSave));
  await t.pump();
}

void main() {
  for (final shell in [
    (name: 'mobile 360 dp, text 200 %', width: 360.0, cover: 120.0, scale: 2.0),
    (name: 'desktop 1280 dp', width: 1280.0, cover: 200.0, scale: 1.0),
  ]) {
    uiTest('${shell.name}: layout and prefilled fields', (t) async {
      final h = await PlaylistUiHarness.pump(
        t,
        width: shell.width,
        textScale: shell.scale,
      );
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h, description: 'Line 1\nLine 2');
      await _open(t, h, src);

      expect(find.text(l10n.playlistEditTitle), findsOneWidget);
      expect(t.widget<TextField>(_name()).controller!.text, 'Src');
      expect(
        t.widget<TextField>(_description()).controller!.text,
        'Line 1\nLine 2',
      );
      expect(t.getSize(find.byType(PlaylistCover)).width, shell.cover);
      if (shell.width >= 1200) {
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(t.getSize(find.byType(AlertDialog)).width, 620);
        expect(find.text(l10n.playlistCancel), findsOneWidget);
      } else {
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(l10n.playlistCancel), findsNothing);
      }
      expect(canTap(t, _save(l10n.playlistSave)), isTrue);
    });
  }

  uiTest('unchanged Save closes without a write or a toast', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await _tapSave(t, h);
    await t.pumpAndSettle();
    expect(h.store.updateCalls, 0);
    expect(find.text(l10n.playlistEditTitle), findsNothing);
    expect(find.text(l10n.playlistSaved), findsNothing);
  });

  uiTest('name only: saved, description kept, toast', (t) async {
    final h = await PlaylistUiHarness.pump(t, width: 1280);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h, description: 'keep me');
    await _open(t, h, src);
    await t.enterText(_name(), '  New name ');
    await t.pump();
    await _tapSave(t, h);
    await eventually(
      t,
      () => find.text(l10n.playlistSaved).evaluate().isNotEmpty,
      what: 'saved toast',
    );
    await t.pumpAndSettle();
    final now = await _stored(t, h, src.uid);
    expect(now.name, 'New name');
    expect(now.description, 'keep me');
    expect(find.byType(AlertDialog), findsNothing);
  });

  uiTest('description keeps its line breaks', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.enterText(_description(), 'one\n\ntwo');
    await t.pump();
    await _tapSave(t, h);
    await eventually(
      t,
      () => find.text(l10n.playlistSaved).evaluate().isNotEmpty,
      what: 'saved toast',
    );
    expect((await _stored(t, h, src.uid)).description, 'one\n\ntwo');
  });

  uiTest('blank name or too long description disables Save', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.enterText(_name(), '   ');
    await t.pump();
    expect(find.text(l10n.playlistNameEmpty), findsOneWidget);
    expect(canTap(t, _save(l10n.playlistSave)), isFalse);

    await t.enterText(_name(), 'Ok');
    await t.enterText(_description(), 'd' * 2001);
    await t.pump();
    expect(find.text(l10n.playlistDescriptionTooLong), findsOneWidget);
    expect(find.text(l10n.plScreensCharCount(2001, 2000)), findsOneWidget);
    expect(canTap(t, _save(l10n.playlistSave)), isFalse);

    await t.enterText(_description(), 'd' * 2000);
    await t.pump();
    expect(canTap(t, _save(l10n.playlistSave)), isTrue);
    expect(h.store.updateCalls, 0);
  });

  uiTest('playlist deleted meanwhile: closes with the not-found toast', (
    t,
  ) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.runAsync(() => h.fixture.repo.deletePlaylist(src.uid));
    await t.enterText(_name(), 'Renamed');
    await t.pump();
    await _tapSave(t, h);
    await eventually(
      t,
      () => find.text(l10n.playlistNotFoundTitle).evaluate().isNotEmpty,
      what: 'not-found toast',
    );
    await t.pumpAndSettle();
    expect(find.text(l10n.playlistEditTitle), findsNothing);
  });

  for (final width in [400.0, 1280.0]) {
    uiTest('failure at $width dp keeps the dialog; retry saves', (t) async {
      final h = await PlaylistUiHarness.pump(t, width: width);
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h);
      h.store.updateError = StateError('locked');
      await _open(t, h, src);
      await t.enterText(_name(), 'Again');
      await t.pump();
      await _tapSave(t, h);
      await eventually(
        t,
        () => find.text(l10n.playlistSaveFailed).evaluate().isNotEmpty,
        what: 'failure toast',
      );
      expect(find.text(l10n.playlistEditTitle), findsOneWidget);
      expect(canTap(t, _save(l10n.playlistSave)), isTrue);
      expect((await _stored(t, h, src.uid)).name, 'Src');

      h.store.updateError = null;
      await _tapSave(t, h);
      await eventually(
        t,
        () => find.text(l10n.playlistEditTitle).evaluate().isEmpty,
        what: 'dialog closed',
      );
      await t.pumpAndSettle();
      expect((await _stored(t, h, src.uid)).name, 'Again');
    });
  }

  uiTest('desktop: a double tap on Save writes once', (t) async {
    final h = await PlaylistUiHarness.pump(t, width: 1280);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.enterText(_name(), 'Once');
    await t.pump();
    final save = _save(l10n.playlistSave);
    await t.tap(save);
    await t.tap(save, warnIfMissed: false);
    await eventually(
      t,
      () => find.text(l10n.playlistEditTitle).evaluate().isEmpty,
      what: 'dialog closed',
    );
    await t.pumpAndSettle();
    expect(h.store.updateCalls, 1);
  });

  uiTest('Cancel, close and Back write nothing', (t) async {
    final h = await PlaylistUiHarness.pump(t, width: 1280);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.enterText(_name(), 'Dropped');
    await t.tap(find.text(l10n.playlistCancel));
    await t.pumpAndSettle();
    expect(find.text(l10n.playlistEditTitle), findsNothing);

    // Mobile: the close button, then the system Back.
    t.view.physicalSize = const Size(400, 900);
    await t.pumpAndSettle();
    await _open(t, h, src);
    await t.enterText(_name(), 'Dropped');
    await t.tap(byIconButton(l10n.playlistClose));
    await t.pumpAndSettle();
    expect(find.text(l10n.playlistEditTitle), findsNothing);
    await _open(t, h, src);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text(l10n.playlistEditTitle), findsNothing);
    expect(h.store.updateCalls, 0);
    expect((await _stored(t, h, src.uid)).name, 'Src');
  });

  uiTest('no custom cover: states the automatic cover, no button', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await eventually(
      t,
      () => find.text(l10n.playlistCoverUsingAuto).evaluate().isNotEmpty,
      what: 'cover state',
    );
    expect(find.text(l10n.playlistCoverAuto), findsNothing);
    expect(find.text(l10n.playlistCoverChoose), findsOneWidget);
  });

  uiTest('automatic cover is staged, applied only on Save', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await h.giveCustomCover(t, src.uid);
    await _open(t, h, src);
    await eventually(
      t,
      () => find.text(l10n.playlistCoverAuto).evaluate().isNotEmpty,
      what: 'automatic cover button',
    );
    await t.tap(find.text(l10n.playlistCoverAuto));
    await t.pump();
    expect(find.text(l10n.playlistCoverUsingAuto), findsOneWidget);
    expect(find.text(l10n.playlistCoverAuto), findsNothing);
    // Staged only: the custom cover is still stored.
    expect(
      await t.runAsync(() => customCoverKey(h.fixture.db, 'playlist', src.uid)),
      isNotNull,
    );

    // Cancel after staging leaves it.
    await t.tap(byIconButton(l10n.playlistClose));
    await t.pumpAndSettle();
    expect(
      await t.runAsync(() => customCoverKey(h.fixture.db, 'playlist', src.uid)),
      isNotNull,
    );

    await _open(t, h, src);
    await eventually(
      t,
      () => find.text(l10n.playlistCoverAuto).evaluate().isNotEmpty,
      what: 'automatic cover button',
    );
    await t.tap(find.text(l10n.playlistCoverAuto));
    await t.pump();
    await _tapSave(t, h);
    await eventually(
      t,
      () => find.text(l10n.playlistSaved).evaluate().isNotEmpty,
      what: 'saved toast',
    );
    expect(
      await t.runAsync(() => customCoverKey(h.fixture.db, 'playlist', src.uid)),
      isNull,
    );
    // The text did not change: no text write was needed to reach the cover.
    expect(h.store.updateCalls, 1);
  });

  uiTest('cover failure: text saved, closes, cover toast', (t) async {
    final h = await PlaylistUiHarness.pump(
      t,
      overrides: [
        customCoverControllerProvider.overrideWithValue(_FailingCovers()),
      ],
    );
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await h.giveCustomCover(t, src.uid);
    await _open(t, h, src);
    await eventually(
      t,
      () => find.text(l10n.playlistCoverAuto).evaluate().isNotEmpty,
      what: 'automatic cover button',
    );
    await t.tap(find.text(l10n.playlistCoverAuto));
    await t.enterText(_name(), 'Renamed');
    await t.pump();
    await _tapSave(t, h);
    await eventually(
      t,
      () => find.text(l10n.plScreensCoverFailed).evaluate().isNotEmpty,
      what: 'cover toast',
    );
    await t.pumpAndSettle();
    expect(find.text(l10n.playlistEditTitle), findsNothing);
    expect((await _stored(t, h, src.uid)).name, 'Renamed');
  });

  uiTest('Change cover… calls the picker', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.tap(find.text(l10n.playlistCoverChoose));
    await t.pump();
    // The seed picker shows its coming-soon notice.
    expect(find.text(l10n.appComingSoon), findsOneWidget);
  });

  uiTest('mobile Save closes its own route, not one opened above it', (
    t,
  ) async {
    final h = await PlaylistUiHarness.pump(t);
    final l10n = h.l10n(t);
    final src = await seedPlaylist(t, h);
    await _open(t, h, src);
    await t.enterText(_name(), 'Slow');
    await t.pump();
    h.store.updateGate = Completer<void>();
    await _tapSave(t, h);
    final dialogRoute = ModalRoute.of(
      t.element(find.text(l10n.playlistEditTitle)),
    )!;
    final nav = h.router.routerDelegate.navigatorKey.currentState!;
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('OVER')),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    h.store.updateGate!.complete();
    await eventually(
      t,
      () => find.text(l10n.playlistSaved).evaluate().isNotEmpty,
      what: 'saved toast',
    );
    await t.pumpAndSettle();
    // The picker above is untouched; only the dialog's own route went.
    expect(find.text('OVER'), findsOneWidget);
    expect(dialogRoute.isActive, isFalse);
    expect(find.text(l10n.playlistEditTitle), findsNothing);
  });

  for (final width in [400.0, 1280.0]) {
    uiTest('fields and cover buttons are disabled while saving at $width dp', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      final h = await PlaylistUiHarness.pump(t, width: width);
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h);
      await h.giveCustomCover(t, src.uid);
      await _open(t, h, src);
      await eventually(
        t,
        () => find.text(l10n.playlistCoverAuto).evaluate().isNotEmpty,
        what: 'cover buttons',
      );
      // The enabled flag of the field's own semantics node.
      bool enabled(Finder f) =>
          t
              .getSemantics(
                find.descendant(of: f, matching: find.byType(EditableText)),
              )
              .getSemanticsData()
              .flagsCollection
              .isEnabled
              .name ==
          'isTrue';
      expect(enabled(_name()), isTrue);
      expect(enabled(_description()), isTrue);
      expect(canTap(t, _save(l10n.playlistCoverChoose)), isTrue);
      expect(canTap(t, _save(l10n.playlistCoverAuto)), isTrue);

      await t.enterText(_name(), 'Busy');
      await t.pump();
      h.store.updateGate = Completer<void>();
      await _tapSave(t, h);
      await t.pump(const Duration(milliseconds: 50));
      expect(enabled(_name()), isFalse);
      expect(enabled(_description()), isFalse);
      expect(canTap(t, _save(l10n.playlistCoverChoose)), isFalse);
      expect(canTap(t, _save(l10n.playlistCoverAuto)), isFalse);

      h.store.updateGate!.complete();
      await eventually(
        t,
        () => find.text(l10n.playlistEditTitle).evaluate().isEmpty,
        what: 'dialog closed',
      );
      handle.dispose();
    });
  }

  uiTest('Favorites is never offered', (t) async {
    final h = await PlaylistUiHarness.pump(t);
    final fav = (await t.runAsync(() => h.fixture.repo.watchSummaries().first))!
        .favorites;
    expect(fav.uid, PlaylistUids.favorites);
    expect(
      () => h.launch(t, (c) => showEditPlaylistDialog(c, fav)),
      throwsAssertionError,
    );
  });
}
