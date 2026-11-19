import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/ui/covers/pick_custom_cover.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'cover_test_support.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('kanaru_optst_'));
  tearDown(() => dir.deleteSync(recursive: true));

  const loaded = CoverDialogOptions(
    itemName: 'Mix',
    automaticCoverKeys: [],
    current: null,
    suggestions: [],
  );

  /// Opens the dialog with [read] as the options provider.
  Future<void> open(
    WidgetTester tester,
    Future<CoverDialogOptions> Function() read,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverDialogOptionsProvider.overrideWith((ref, i) => read()),
          customCoverControllerProvider.overrideWithValue(
            FakeCoverController(dir),
          ),
          imageFilePickerProvider.overrideWithValue(FakePicker()),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    pickCustomCover(context, CustomCoverKind.playlist, 'pl'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder save() => find.widgetWithText(FilledButton, 'Lưu');
  bool saveOn(WidgetTester t) =>
      t.widget<FilledButton>(save()).onPressed != null;

  testWidgets('loading: skeleton rows, no choices, Lưu off', (tester) async {
    final never = Completer<CoverDialogOptions>();
    await open(tester, () => never.future);
    expect(
      find.byWidgetPredicate((w) => w is KMediaCard && w.loading),
      findsNWidgets(3),
    );
    expect(find.byType(SelectionRow), findsNothing);
    expect(find.text('Tự động'), findsNothing);
    expect(saveOn(tester), isFalse);
  });

  testWidgets('error: message and Thử lại, retry reads again', (tester) async {
    var calls = 0;
    await open(tester, () async {
      if (++calls == 1) throw StateError('boom');
      return loaded;
    });
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh sách'), findsOneWidget);
    expect(find.byType(SelectionRow), findsNothing);
    expect(saveOn(tester), isFalse);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Không tải được danh sách'), findsNothing);
    expect(find.text('Tự động'), findsOneWidget);
  });
}
