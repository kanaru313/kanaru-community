import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_controller.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_state.dart';
import 'package:kanaru/src/library/state/covers/cover_texts.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';

import 'cover_test_support.dart';

const _texts = CoverTexts(
  changed: 'changed',
  resetDone: 'reset',
  undo: 'undo',
  undoFailed: 'undo failed',
  errorFormat: 'bad format',
  errorRead: 'cannot read',
);
const _item = (kind: CustomCoverKind.playlist, itemKey: 'pl');
const _args = (kind: CustomCoverKind.playlist, itemKey: 'pl', draft: null);

/// Switching between rows after a pick: the picked row stays and each row
/// saves exactly what it shows.
void main() {
  late Directory dir;
  late FakeCoverController cover;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_dlg_sel_');
    cover = FakeCoverController(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  CoverSuggestion album(String name) => CoverSuggestion(
    albumKey: name,
    title: name,
    year: null,
    thumb: File('${dir.path}/$name-thumb.jpg'),
    full: File('${dir.path}/$name-full.jpg'),
  );

  Future<({ProviderContainer c, CoverDialogController ctl})> open({
    bool hasCurrent = true,
  }) async {
    final options = CoverDialogOptions(
      itemName: 'Mix',
      automaticCoverKeys: const [],
      current: hasCurrent
          ? (
              thumb: File('${dir.path}/cur-thumb.jpg'),
              full: File('${dir.path}/cur-full.jpg'),
            )
          : null,
      suggestions: [album('a'), album('b')],
    );
    final c = ProviderContainer(
      overrides: [
        coverDialogOptionsProvider.overrideWith((ref, i) async => options),
        customCoverControllerProvider.overrideWithValue(cover),
      ],
    );
    addTearDown(c.dispose);
    c.listen(coverDialogControllerProvider(_args), (_, _) {});
    await c.read(coverDialogOptionsProvider(_item).future);
    await Future<void>.delayed(Duration.zero);
    return (c: c, ctl: c.read(coverDialogControllerProvider(_args).notifier));
  }

  CoverDialogState stateOf(ProviderContainer c) =>
      c.read(coverDialogControllerProvider(_args));

  Future<ScaffoldMessengerState> messengerOf(WidgetTester tester) async {
    late ScaffoldMessengerState m;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              m = ScaffoldMessenger.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return m;
  }

  testWidgets('pick, other row, back to the pick: it stays and saves its '
      'file with its crop', (tester) async {
    final messenger = await messengerOf(tester);
    await tester.runAsync(() async {
      final d = await open();
      final image = pickedFile(dir, 'p.png');
      await d.ctl.drop(image);
      final preview = stateOf(d.c).picked!.preview!.file;

      for (final other in [
        CoverRowIds.automatic,
        CoverRowIds.current,
        'album:a',
      ]) {
        d.ctl.select(other);
        expect(stateOf(d.c).selectedId, other);
        expect(stateOf(d.c).picked, isNotNull, reason: 'kept after $other');
        expect(stateOf(d.c).picked!.reading, isFalse);
        expect(image.file.existsSync(), isTrue);
        expect(preview.existsSync(), isTrue);
      }
      d.ctl.select(CoverRowIds.picked);
      expect(stateOf(d.c).selectedId, CoverRowIds.picked);
      expect(await d.ctl.save(messenger: messenger, texts: _texts), isTrue);
      final choice = cover.changes.single.choice;
      expect(choice, isA<FileCover>());
      expect((choice as FileCover).image.path, image.file.path);
    });
  });

  testWidgets('pick then Tự động saves automatic; the pick is kept until '
      'the dialog closes', (tester) async {
    final messenger = await messengerOf(tester);
    await tester.runAsync(() async {
      final d = await open();
      final image = pickedFile(dir, 'p.png');
      await d.ctl.drop(image);
      d.ctl.select(CoverRowIds.automatic);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(image.file.existsSync(), isTrue);
      expect(await d.ctl.save(messenger: messenger, texts: _texts), isTrue);
      expect(cover.changes.single.choice, isA<AutomaticCover>());
      // the unused pick is not handed to the job's choice, so it is deleted
      // when the dialog closes
      d.c.dispose();
      await waitUntil(() => !image.file.existsSync());
    });
  });

  testWidgets('pick then an album saves that album file', (tester) async {
    final messenger = await messengerOf(tester);
    await tester.runAsync(() async {
      final d = await open();
      await d.ctl.drop(pickedFile(dir, 'p.png'));
      d.ctl.select('album:b');
      expect(await d.ctl.save(messenger: messenger, texts: _texts), isTrue);
      final choice = cover.changes.single.choice as FileCover;
      expect(choice.image.path, '${dir.path}/b-full.jpg');
    });
  });

  testWidgets('pick, album, back to the opening row: nothing to save', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final d = await open();
      await d.ctl.drop(pickedFile(dir, 'p.png'));
      d.ctl.select('album:a');
      d.ctl.select(CoverRowIds.current);
      expect(stateOf(d.c).changed, isFalse);
      expect(stateOf(d.c).picked, isNotNull);
    });
  });

  testWidgets('options reloading keeps the pick and the choice', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final d = await open();
      await d.ctl.drop(pickedFile(dir, 'p.png'));
      d.ctl.select('album:a');
      d.c.invalidate(coverDialogOptionsProvider(_item));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(stateOf(d.c).picked, isNotNull);
      expect(stateOf(d.c).selectedId, 'album:a');
      expect(stateOf(d.c).opening, isNotNull);
    });
  });

  testWidgets('a failed second pick keeps the first and saves it', (
    tester,
  ) async {
    final messenger = await messengerOf(tester);
    await tester.runAsync(() async {
      final d = await open();
      final first = pickedFile(dir, 'one.png');
      await d.ctl.drop(first);
      cover.previewError = const FormatException('bad');
      await d.ctl.drop(pickedFile(dir, 'two.png'));
      cover.previewError = null;
      expect(stateOf(d.c).picked!.image.name, 'one.png');
      expect(stateOf(d.c).selectedId, CoverRowIds.picked);
      expect(first.file.existsSync(), isTrue);
      expect(await d.ctl.save(messenger: messenger, texts: _texts), isTrue);
      final choice = cover.changes.single.choice as FileCover;
      expect(choice.image.path, first.file.path);
    });
  });

  testWidgets('switching row while the pick is still read keeps the pick', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final d = await open();
      cover.previewGate = Completer<void>();
      final reading = d.ctl.drop(pickedFile(dir, 'one.png'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      d.ctl.select('album:a');
      cover.previewGate!.complete();
      await reading;
      expect(stateOf(d.c).picked?.reading, isFalse);
      expect(stateOf(d.c).selectedId, 'album:a');
    });
  });
}
