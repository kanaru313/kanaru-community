import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/state/covers/cover_choice_resolver.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_controller.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_state.dart';
import 'package:kanaru/src/library/state/covers/cover_draft.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';

import 'cover_test_support.dart';

void main() {
  late Directory dir;
  late FakeCoverController cover;
  late FakePicker picker;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_dlg_');
    cover = FakeCoverController(dir);
    picker = FakePicker();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  const kind = CustomCoverKind.playlist;
  const item = (kind: kind, itemKey: 'pl');

  CoverSuggestion suggestion(String name) => CoverSuggestion(
    albumKey: name,
    title: name,
    year: null,
    thumb: File('${dir.path}/$name-thumb.jpg'),
    full: File('${dir.path}/$name-full.jpg'),
  );

  /// Opens a dialog on [item]; [hasCurrent] gives the item a custom cover.
  ProviderContainer open({bool hasCurrent = false, CoverDraft? draft}) {
    final options = CoverDialogOptions(
      itemName: 'Mix',
      automaticCoverKeys: const [],
      current: hasCurrent
          ? (
              thumb: File('${dir.path}/cur-thumb.jpg'),
              full: File('${dir.path}/cur-full.jpg'),
            )
          : null,
      suggestions: [suggestion('a'), suggestion('b')],
    );
    final container = ProviderContainer(
      overrides: [
        coverDialogOptionsProvider.overrideWith((ref, i) async => options),
        customCoverControllerProvider.overrideWithValue(cover),
        imageFilePickerProvider.overrideWithValue(picker),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<CoverDialogController> opened(
    ProviderContainer c, {
    CoverDraft? draft,
  }) async {
    final a = (kind: kind, itemKey: 'pl', draft: draft);
    c.listen(coverDialogControllerProvider(a), (_, _) {});
    await c.read(coverDialogOptionsProvider(item).future);
    await Future<void>.delayed(Duration.zero);
    return c.read(coverDialogControllerProvider(a).notifier);
  }

  CoverDialogState stateOf(ProviderContainer c, {CoverDraft? draft}) => c.read(
    coverDialogControllerProvider((kind: kind, itemKey: 'pl', draft: draft)),
  );

  test('opens on the current custom cover, else on automatic', () async {
    final withCurrent = open(hasCurrent: true);
    await opened(withCurrent);
    expect(stateOf(withCurrent).selectedId, CoverRowIds.current);
    expect(stateOf(withCurrent).changed, isFalse);

    final without = open();
    await opened(without);
    expect(stateOf(without).selectedId, CoverRowIds.automatic);
  });

  test('changed is false until another row is chosen', () async {
    final c = open(hasCurrent: true);
    final ctl = await opened(c);
    ctl.select(CoverRowIds.automatic);
    expect(stateOf(c).changed, isTrue);
    ctl.select(CoverRowIds.current);
    expect(stateOf(c).changed, isFalse);
    ctl.select('nope');
    expect(stateOf(c).selectedId, CoverRowIds.current);
  });

  test('a picked image gets its row with its upright size', () async {
    final c = open();
    final ctl = await opened(c);
    picker.next = pickedFile(dir, 'p.jpg');
    cover.sizes[picker.next!.file.path] = (w: 4000, h: 3000);
    await ctl.pick();
    final s = stateOf(c);
    expect(s.selectedId, CoverRowIds.picked);
    expect(s.picked!.preview!.width, 4000);
    expect(s.picked!.preview!.height, 3000);
    expect(s.changed, isTrue);
    expect(s.error, isNull);
  });

  test(
    'while the image is read the row is reading and nothing is changed',
    () async {
      final c = open();
      final ctl = await opened(c);
      cover.previewGate = Completer<void>();
      picker.next = pickedFile(dir, 'p.jpg');
      final done = ctl.pick();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(stateOf(c).reading, isTrue);
      expect(stateOf(c).changed, isFalse);
      cover.previewGate!.complete();
      await done;
      expect(stateOf(c).reading, isFalse);
      expect(stateOf(c).changed, isTrue);
    },
  );

  test('the dialog label goes to the picker', () async {
    final c = open();
    final ctl = await opened(c);
    await ctl.pick(dialogLabel: 'Ảnh');
    expect(picker.lastLabel, 'Ảnh');
  });

  test(
    'closing while a superseded pick is deleted drops the new image too',
    () async {
      final c = open();
      final ctl = await opened(c);
      cover.previewGate = Completer<void>();
      final first = pickedFile(dir, 'first.jpg');
      picker.next = first;
      final firstDone = ctl.pick();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(stateOf(c).reading, isTrue);

      final second = pickedFile(dir, 'second.jpg');
      final secondDone = ctl.drop(second); // awaits the delete of `first`
      c.dispose(); // the dialog closes during that delete
      await secondDone; // must not throw
      cover.previewGate!.complete();
      await firstDone;

      expect(second.file.existsSync(), isFalse);
      expect(first.file.existsSync(), isFalse);
    },
  );

  test('a cancelled picker changes nothing', () async {
    final c = open();
    final ctl = await opened(c);
    await ctl.pick();
    expect(stateOf(c).picked, isNull);
    expect(stateOf(c).error, isNull);
  });

  test('a picker failure is an error value and no row', () async {
    final c = open();
    final ctl = await opened(c);
    picker.error = PlatformException(code: 'boom');
    await ctl.pick();
    expect(stateOf(c).error, isNotNull);
    expect(stateOf(c).picked, isNull);
    expect(stateOf(c).selectedId, CoverRowIds.automatic);
    ctl.clearError();
    expect(stateOf(c).error, isNull);
  });

  test('an unreadable image: error, no row, temp copy deleted', () async {
    final c = open(hasCurrent: true);
    final ctl = await opened(c);
    final image = pickedFile(dir, 'bad.jpg');
    picker.next = image;
    cover.previewError = const FormatException('not an image');
    await ctl.pick();
    final s = stateOf(c);
    expect(s.error!.cause, isA<FormatException>());
    expect(s.picked, isNull);
    expect(s.selectedId, CoverRowIds.current, reason: 'back to the old row');
    expect(image.file.existsSync(), isFalse);
  });

  test('picking again deletes the earlier temp copy and preview', () async {
    final c = open();
    final ctl = await opened(c);
    final first = pickedFile(dir, 'one.jpg');
    picker.next = first;
    await ctl.pick();
    final firstPreview = stateOf(c).picked!.preview!.file;
    final second = pickedFile(dir, 'two.jpg');
    picker.next = second;
    await ctl.pick();
    await Future<void>.delayed(Duration.zero);
    expect(first.file.existsSync(), isFalse);
    expect(firstPreview.existsSync(), isFalse);
    expect(second.file.existsSync(), isTrue);
    expect(stateOf(c).picked!.image, same(second));
  });

  test(
    'a non-square image is cut in the middle; a square one is not',
    () async {
      final c = open();
      final ctl = await opened(c);
      final tall = pickedFile(dir, 'tall.jpg');
      cover.sizes[tall.file.path] = (w: 3000, h: 4000);
      await ctl.drop(tall);
      expect(stateOf(c).crop, const CoverCrop(left: 0, top: 500, side: 3000));
      final choice = await resolveCoverChoice(cover, stateOf(c));
      expect((choice as FileCover).crop, stateOf(c).crop);
      ctl.setOffset(0);
      expect(stateOf(c).crop!.top, 0);

      final square = pickedFile(dir, 'sq.jpg');
      cover.sizes[square.file.path] = (w: 800, h: 800);
      await ctl.drop(square);
      expect(stateOf(c).crop, isNull);
      expect(stateOf(c).panPossible, isFalse);
      final sqChoice = await resolveCoverChoice(cover, stateOf(c));
      expect((sqChoice as FileCover).crop, isNull);
    },
  );

  test('the form draft keeps the temp files after the dialog closes', () async {
    final c = open();
    final ctl = await opened(c);
    final image = pickedFile(dir, 'p.jpg');
    await ctl.drop(image);
    final preview = stateOf(c).picked!.preview!.file;
    final draft = await ctl.toDraft();
    expect(draft!.picked!.image, same(image));
    expect(draft.choice, isA<FileCover>());
    expect(draft.displayFile!.path, preview.path);
    c.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(image.file.existsSync(), isTrue);
    expect(preview.existsSync(), isTrue);
    await draft.discard();
    expect(image.file.existsSync(), isFalse);
    expect(preview.existsSync(), isFalse);
  });

  test(
    'reopened on a draft: picked row is chosen, its files stay the form\'s',
    () async {
      final c1 = open();
      final ctl1 = await opened(c1);
      await ctl1.drop(pickedFile(dir, 'p.jpg'));
      final draft = (await ctl1.toDraft())!;

      final c2 = open();
      await opened(c2, draft: draft);
      expect(stateOf(c2, draft: draft).selectedId, CoverRowIds.picked);
      expect(stateOf(c2, draft: draft).changed, isFalse);
      c2.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(draft.picked!.image.file.existsSync(), isTrue);
    },
  );

  test(
    'going back to the stored cover gives a draft without a choice',
    () async {
      final c = open(hasCurrent: true);
      final ctl = await opened(c);
      ctl.select(CoverRowIds.automatic);
      ctl.select(CoverRowIds.current);
      expect(await ctl.toDraft(), isNull, reason: 'nothing changed');
    },
  );

  test('dispose deletes the files it still owns', () async {
    final c = open();
    final ctl = await opened(c);
    final image = pickedFile(dir, 'p.jpg');
    await ctl.drop(image);
    final preview = stateOf(c).picked!.preview!.file;
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(image.file.existsSync(), isFalse);
    expect(preview.existsSync(), isFalse);
  });

  test('a file the user owns is never deleted, only its preview', () async {
    final c = open();
    final ctl = await opened(c);
    final own = pickedFile(dir, 'mine.jpg', temporary: false);
    await ctl.drop(own);
    final preview = stateOf(c).picked!.preview!.file;
    await ctl.drop(pickedFile(dir, 'next.jpg', temporary: false));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(own.file.existsSync(), isTrue);
    expect(preview.existsSync(), isFalse);
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(own.file.existsSync(), isTrue);
  });

  test('a drop that finishes after the dialog closed cleans up', () async {
    final c = open();
    final ctl = await opened(c);
    cover.previewGate = Completer<void>();
    final image = pickedFile(dir, 'late.jpg');
    final done = ctl.drop(image);
    await Future<void>.delayed(Duration.zero);
    c.dispose();
    cover.previewGate!.complete();
    await done;
    expect(image.file.existsSync(), isFalse);
    for (final p in cover.previews) {
      expect(p.existsSync(), isFalse);
    }
  });

  test('a failed preview leaves a row the user chose meanwhile', () async {
    final c = open();
    final ctl = await opened(c);
    cover.previewGate = Completer<void>();
    cover.previewError = const FormatException('bad');
    final done = ctl.drop(pickedFile(dir, 'bad.jpg'));
    await Future<void>.delayed(Duration.zero);
    ctl.select('album:a');
    expect(stateOf(c).selectedId, 'album:a');
    cover.previewGate!.complete();
    await done;
    expect(stateOf(c).selectedId, 'album:a');
    expect(stateOf(c).picked, isNull);
    expect(stateOf(c).error, isNotNull);
  });

  test('a failed second pick leaves the first pick intact', () async {
    final c = open();
    final ctl = await opened(c);
    final first = pickedFile(dir, 'one.jpg');
    await ctl.drop(first);
    final firstPreview = stateOf(c).picked!.preview!.file;
    ctl.setOffset(0.2);

    final second = pickedFile(dir, 'two.jpg');
    cover.previewError = const FormatException('bad');
    await ctl.drop(second);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final s = stateOf(c);
    expect(s.picked!.image, same(first));
    expect(s.selectedId, CoverRowIds.picked);
    expect(s.offset, 0.2);
    expect(s.error, isNotNull);
    expect(first.file.existsSync(), isTrue);
    expect(firstPreview.existsSync(), isTrue);
    expect(second.file.existsSync(), isFalse);

    // Still the controller's: dispose deletes it.
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(first.file.existsSync(), isFalse);
    expect(firstPreview.existsSync(), isFalse);
  });

  test('the first pick is deleted only once the second is ready', () async {
    final c = open();
    final ctl = await opened(c);
    final first = pickedFile(dir, 'one.jpg');
    await ctl.drop(first);
    cover.previewGate = Completer<void>();
    final done = ctl.drop(pickedFile(dir, 'two.jpg'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(first.file.existsSync(), isTrue, reason: 'new one still reading');
    cover.previewGate!.complete();
    await done;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(first.file.existsSync(), isFalse);
  });

  test('a dialog closed while the second pick reads deletes both', () async {
    final c = open();
    final ctl = await opened(c);
    final first = pickedFile(dir, 'one.jpg');
    await ctl.drop(first);
    final firstPreview = stateOf(c).picked!.preview!.file;
    cover.previewGate = Completer<void>();
    final second = pickedFile(dir, 'two.jpg');
    final done = ctl.drop(second);
    await Future<void>.delayed(Duration.zero);
    c.dispose();
    cover.previewGate!.complete();
    await done;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(first.file.existsSync(), isFalse);
    expect(firstPreview.existsSync(), isFalse);
    expect(second.file.existsSync(), isFalse);
  });

  test('a failed pick on a reopened draft keeps the draft row', () async {
    final c1 = open();
    final ctl1 = await opened(c1);
    await ctl1.drop(pickedFile(dir, 'p.jpg'));
    final draft = (await ctl1.toDraft())!;

    final c2 = open();
    final ctl2 = await opened(c2, draft: draft);
    cover.previewError = const FormatException('bad');
    await ctl2.drop(pickedFile(dir, 'bad.jpg'));

    final s = stateOf(c2, draft: draft);
    expect(s.picked, same(draft.picked));
    expect(s.selectedId, CoverRowIds.picked);
    expect(s.changed, isFalse, reason: 'the draft row is still the choice');
    c2.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(draft.picked!.image.file.existsSync(), isTrue);
  });

  test('a dispose while the draft is made does not delete its files', () async {
    final c = open();
    final ctl = await opened(c);
    final image = pickedFile(dir, 'p.jpg');
    await ctl.drop(image);
    final preview = stateOf(c).picked!.preview!.file;
    final drafting = ctl.toDraft(); // takes the files before its first await
    c.dispose();
    final draft = await drafting;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(draft, isNotNull);
    expect(image.file.existsSync(), isTrue);
    expect(preview.existsSync(), isTrue);
    await draft!.discard();
  });
}
