import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_controller.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/covers/cover_texts.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/platform/domain/image_file_picker.dart';
import 'package:material_ui/material_ui.dart';

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

/// `CoverDialogController.save` with a picked image: who owns its temp files
/// while the job runs, and after it succeeds or fails.
void main() {
  late Directory dir;
  late FakeCoverController cover;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_dlg_save_');
    cover = FakeCoverController(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<ScaffoldMessengerState> pumpMessenger(WidgetTester tester) async {
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              messenger = ScaffoldMessenger.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return messenger;
  }

  /// A dialog with a picked image chosen (so Save is enabled).
  Future<({ProviderContainer c, CoverDialogController ctl, PickedImage image})>
  dialogWithPick() async {
    final c = ProviderContainer(
      overrides: [
        coverDialogOptionsProvider.overrideWith(
          (ref, i) async => const CoverDialogOptions(
            itemName: 'Mix',
            automaticCoverKeys: [],
            current: null,
            suggestions: [],
          ),
        ),
        customCoverControllerProvider.overrideWithValue(cover),
      ],
    );
    addTearDown(c.dispose);
    c.listen(coverDialogControllerProvider(_args), (_, _) {});
    await c.read(coverDialogOptionsProvider(_item).future);
    await Future<void>.delayed(Duration.zero);
    final ctl = c.read(coverDialogControllerProvider(_args).notifier);
    final image = pickedFile(dir, 'p.jpg');
    await ctl.drop(image);
    return (c: c, ctl: ctl, image: image);
  }

  testWidgets('Save hands the files to the job: closing the dialog keeps them '
      'until the save is done, then the job deletes them', (tester) async {
    final messenger = await pumpMessenger(tester);
    await tester.runAsync(() async {
      final d = await dialogWithPick();
      final preview = d.c.read(coverDialogControllerProvider(_args)).picked!;
      final previewFile = preview.preview!.file;
      cover.gate = Completer<void>();

      final saving = d.ctl.save(messenger: messenger, texts: _texts);
      await Future<void>.delayed(Duration.zero);
      d.c.dispose(); // the dialog closes while the job runs
      // Nothing positive to wait for: give a wrong delete time to happen.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(d.image.file.existsSync(), isTrue, reason: 'the job owns them');
      expect(previewFile.existsSync(), isTrue);

      cover.gate!.complete();
      expect(await saving, isTrue);
      expect(cover.changes.single.choice, isA<FileCover>());
      expect(d.image.file.existsSync(), isFalse);
      expect(previewFile.existsSync(), isFalse);
    });
  });

  testWidgets('a failure while the dialog is open gives the files back', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    await tester.runAsync(() async {
      final d = await dialogWithPick();
      final previewFile = d.c
          .read(coverDialogControllerProvider(_args))
          .picked!
          .preview!
          .file;
      cover.changeError = const FileSystemException('disk');

      expect(await d.ctl.save(messenger: messenger, texts: _texts), isFalse);
      var s = d.c.read(coverDialogControllerProvider(_args));
      expect(s.saving, isFalse);
      expect(s.changed, isTrue, reason: 'unlocked, the user can retry');
      expect(d.image.file.existsSync(), isTrue);

      // Retry with the same image works.
      cover.changeError = null;
      expect(await d.ctl.save(messenger: messenger, texts: _texts), isTrue);
      expect(cover.changes, hasLength(1));
      expect(d.image.file.existsSync(), isFalse);
      expect(previewFile.existsSync(), isFalse);
      s = d.c.read(coverDialogControllerProvider(_args));
      expect(s.error, isNull);
    });
  });

  testWidgets('a failed save is cleaned up by Cancel (the dialog closing)', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    await tester.runAsync(() async {
      final d = await dialogWithPick();
      cover.changeError = const FileSystemException('disk');
      expect(await d.ctl.save(messenger: messenger, texts: _texts), isFalse);

      d.c.dispose();
      await waitUntil(() => !d.image.file.existsSync());
      expect(d.image.file.existsSync(), isFalse);
    });
  });

  testWidgets('a failure after the dialog closed deletes the files', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    await tester.runAsync(() async {
      final d = await dialogWithPick();
      final previewFile = d.c
          .read(coverDialogControllerProvider(_args))
          .picked!
          .preview!
          .file;
      cover.gate = Completer<void>();
      cover.changeError = const FileSystemException('disk');

      final saving = d.ctl.save(messenger: messenger, texts: _texts);
      await Future<void>.delayed(Duration.zero);
      d.c.dispose();
      cover.gate!.complete();

      expect(await saving, isFalse);
      await waitUntil(
        () => !d.image.file.existsSync() && !previewFile.existsSync(),
      );
      expect(d.image.file.existsSync(), isFalse);
      expect(previewFile.existsSync(), isFalse);
    });
  });
}
