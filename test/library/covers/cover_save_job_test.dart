import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/covers/cover_save_job.dart';
import 'package:kanaru/src/library/state/covers/cover_texts.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
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

void main() {
  late Directory dir;
  late FakeCoverController controller;
  late File temp;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_job_');
    controller = FakeCoverController(dir);
    temp = File('${dir.path}/picked.jpg')..writeAsBytesSync([1]);
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

  CoverSaveJob job(
    ScaffoldMessengerState messenger, {
    CoverChoice choice = const CoverChoice.automatic(),
    bool Function()? open,
    List<File>? files,
  }) => CoverSaveJob(
    controller: controller,
    kind: CustomCoverKind.album,
    itemKey: 'k',
    choice: () async => choice,
    messenger: messenger,
    texts: _texts,
    ownedFiles: files ?? [temp],
    dialogOpen: open ?? () => false,
  );

  Future<T?> real<T>(WidgetTester tester, Future<T> Function() body) =>
      tester.runAsync(body);

  testWidgets('saves once, shows the snack bar with Undo, deletes temp files', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    final choice = CoverChoice.file(temp);

    final ok = await real(tester, job(messenger, choice: choice).run);
    await tester.pump();

    expect(ok, isTrue);
    expect(controller.changes.single.choice, same(choice));
    expect(controller.changes.single.key, 'k');
    expect(find.text('changed'), findsOneWidget);
    expect(find.text('undo'), findsOneWidget);
    expect(temp.existsSync(), isFalse);
  });

  testWidgets('choosing the automatic cover says so', (tester) async {
    final messenger = await pumpMessenger(tester);
    await real(tester, job(messenger).run);
    await tester.pump();
    expect(find.text('reset'), findsOneWidget);
  });

  /// Runs a job without temp files, so everything stays in the fake-async
  /// zone and `pump` drives it (no real file IO is involved).
  Future<void> runSaved(WidgetTester tester, ScaffoldMessengerState m) async {
    unawaited(job(m, files: const []).run());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapUndo(WidgetTester tester) async {
    await tester.tap(find.text('undo'));
    // The first snack bar leaves, then the queued one slides in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Undo takes the change back and releases nothing else', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    await runSaved(tester, messenger);
    await tapUndo(tester);

    expect(controller.change.undos, 1);
    expect(controller.change.releases, 0);
    expect(find.text('undo failed'), findsNothing);
  });

  for (final failure in <String, void Function(FakeChange)>{
    'false': (c) => c.undoResult = false,
    'an error': (c) => c.undoError = StateError('db'),
  }.entries) {
    testWidgets('Undo that gives ${failure.key} shows the failure text', (
      tester,
    ) async {
      failure.value(controller.change);
      final messenger = await pumpMessenger(tester);
      await runSaved(tester, messenger);
      await tapUndo(tester);

      expect(controller.change.undos, 1);
      expect(find.text('undo failed'), findsOneWidget);
    });
  }

  testWidgets('a snack bar that closes without Undo releases the change', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    await runSaved(tester, messenger);
    expect(controller.change.releases, 0);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(controller.change.releases, 1);
    expect(controller.change.undos, 0);
  });

  testWidgets('a dialog that closes during a slow save still gets the result', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    var open = true;

    final ok = await tester.runAsync(() async {
      // Made inside the real zone: its continuations must run there.
      controller.gate = Completer<void>();
      final running = job(messenger, open: () => open).run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.changes, isEmpty);
      expect(temp.existsSync(), isTrue, reason: 'still saving');
      open = false; // the user dismissed the dialog meanwhile
      controller.gate!.complete();
      return running;
    });
    await tester.pump();

    expect(ok, isTrue);
    expect(find.text('reset'), findsOneWidget);
    expect(controller.changes, hasLength(1));
    expect(temp.existsSync(), isFalse);
  });

  testWidgets('a failure after the dialog closed mid-save deletes the files', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    var open = true;

    final ok = await tester.runAsync(() async {
      controller.gate = Completer<void>();
      controller.changeError = const FileSystemException('x');
      final running = job(messenger, open: () => open).run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      open = false;
      controller.gate!.complete();
      return running;
    });
    await tester.pump();

    expect(ok, isFalse);
    expect(find.text('cannot read'), findsOneWidget);
    expect(temp.existsSync(), isFalse, reason: 'nobody can retry');
  });

  testWidgets('a rejected image shows the format text and deletes temp files', (
    tester,
  ) async {
    controller.changeError = const FormatException('x');
    final messenger = await pumpMessenger(tester);

    final ok = await real(tester, job(messenger).run);
    await tester.pump();

    expect(ok, isFalse);
    expect(find.text('bad format'), findsOneWidget);
    expect(find.text('undo'), findsNothing);
    expect(temp.existsSync(), isFalse);
  });

  for (final error in <String, Object>{
    'a file error': const FileSystemException('timeout'),
    'an unknown error': StateError('native library missing'),
  }.entries) {
    testWidgets('${error.key} shows the read text', (tester) async {
      controller.changeError = error.value;
      final messenger = await pumpMessenger(tester);

      await real(tester, job(messenger).run);
      await tester.pump();

      expect(find.text('cannot read'), findsOneWidget);
      expect(find.text('bad format'), findsNothing);
    });
  }

  testWidgets('after a failure the files stay while the dialog is open', (
    tester,
  ) async {
    controller.changeError = const FileSystemException('x');
    final messenger = await pumpMessenger(tester);

    final ok = await real(tester, job(messenger, open: () => true).run);

    expect(ok, isFalse);
    expect(temp.existsSync(), isTrue, reason: 'the user may retry');
  });

  testWidgets('a choice that cannot be resolved is reported like an import', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    final failing = CoverSaveJob(
      controller: controller,
      kind: CustomCoverKind.album,
      itemKey: 'k',
      choice: () async => throw const FileSystemException('missing'),
      messenger: messenger,
      texts: _texts,
      ownedFiles: [temp],
    );

    expect(await real(tester, failing.run), isFalse);
    await tester.pump();
    expect(find.text('cannot read'), findsOneWidget);
    expect(controller.changes, isEmpty);
  });
}
