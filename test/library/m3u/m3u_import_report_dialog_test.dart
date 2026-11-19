import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_import_report_dialog.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_limits.dart';
import 'package:material_ui/material_ui.dart';

M3uImportResult _result({
  int added = 8,
  int? songsAdded,
  int total = 10,
  int notInLibrary = 0,
  List<M3uProblemLine> problems = const [],
  bool truncated = false,
}) => M3uImportResult(
  playlistUid: 'uid',
  name: 'Road',
  fileName: 'Road.m3u8',
  added: added,
  songsAdded: songsAdded ?? added,
  totalLines: total,
  notInLibrary: notInLibrary,
  outsideFolders: problems
      .where((p) => p.kind == M3uProblemKind.outsideFolders)
      .length,
  notScanned: problems.where((p) => p.kind == M3uProblemKind.notScanned).length,
  notIndexed: problems.where((p) => p.kind == M3uProblemKind.notIndexed).length,
  problems: problems,
  truncated: truncated,
);

List<M3uProblemLine> _lines(M3uProblemKind kind, int n, {int from = 1}) => [
  for (var i = 0; i < n; i++)
    M3uProblemLine(line: from + i, text: '${kind.name}-$i.mp3', kind: kind),
];

/// Pumps the dialog on a fresh app; returns what its buttons popped.
Future<List<bool?>> _pump(
  WidgetTester t,
  M3uImportResult r, {
  String locale = 'en',
  double width = 400,
  double textScale = 1,
  ThemeData? theme,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 900);
  addTearDown(t.view.reset);
  final popped = <bool?>[];
  await t.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      theme: theme,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                popped.add(await showM3uImportReport(context, r)),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('go'));
  await t.pumpAndSettle();
  return popped;
}

void main() {
  late AppLocalizations l10n;
  setUpAll(
    () async => l10n = await AppLocalizations.delegate.load(const Locale('en')),
  );

  testWidgets('summary, title and actions; no group when nothing is wrong', (
    t,
  ) async {
    await _pump(t, _result(problems: const [], truncated: false));
    expect(find.text(l10n.playlistM3uReportTitle), findsOneWidget);
    expect(
      find.text(l10n.playlistM3uReportSummary(8, 10, 'Road.m3u8', 'Road')),
      findsOneWidget,
    );
    expect(find.text(l10n.playlistClose), findsOneWidget);
    expect(find.text(l10n.playlistM3uOpenPlaylist), findsOneWidget);
    expect(find.text(l10n.playlistM3uReportNotInLibrary(0)), findsNothing);
    expect(find.textContaining('Line '), findsNothing);
  });

  testWidgets('not-indexed group: reason text, five lines, rest counted', (
    t,
  ) async {
    await _pump(t, _result(problems: _lines(M3uProblemKind.notIndexed, 7)));
    expect(find.text(l10n.m3uReportNotIndexed(7)), findsOneWidget);
    expect(find.textContaining("Android's media index"), findsOneWidget);
    expect(
      find.text(l10n.playlistM3uReportLine(1, 'notIndexed-0.mp3')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.playlistM3uReportLine(6, 'notIndexed-5.mp3')),
      findsNothing,
    );
    expect(find.text(l10n.playlistM3uReportMore(2)), findsOneWidget);
  });

  testWidgets('not-in-library wording points at the next library scan', (
    t,
  ) async {
    await _pump(t, _result(notInLibrary: 2));
    expect(
      find.text(
        '2 songs are not in your library yet: they appear after the next '
        'library scan.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('not-in-library wording, singular', (t) async {
    await _pump(t, _result(notInLibrary: 1));
    expect(
      find.text(
        '1 song is not in your library yet: it appears after the next '
        'library scan.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('not-in-library group has no lines', (t) async {
    await _pump(t, _result(notInLibrary: 2));
    expect(find.text(l10n.playlistM3uReportNotInLibrary(2)), findsOneWidget);
    expect(find.textContaining('Line '), findsNothing);
  });

  for (final n in [0, 5, 6]) {
    testWidgets('$n lines in a group: cap of 5 and "and N more"', (t) async {
      await _pump(t, _result(problems: _lines(M3uProblemKind.unresolved, n)));
      expect(find.textContaining('Line '), findsNWidgets(n > 5 ? 5 : n));
      expect(
        find.text(l10n.playlistM3uReportMore(1)),
        n == 6 ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(l10n.playlistM3uReportUnresolved(n)),
        n == 0 ? findsNothing : findsOneWidget,
      );
    });
  }

  testWidgets('outside-folder lines join the unusable group in file order', (
    t,
  ) async {
    final problems = [
      const M3uProblemLine(
        line: 4,
        text: 'https://x/y.mp3',
        kind: M3uProblemKind.unresolved,
      ),
      const M3uProblemLine(
        line: 9,
        text: '/sdcard/a.wma',
        kind: M3uProblemKind.outsideFolders,
      ),
    ];
    await _pump(t, _result(problems: problems));
    expect(find.text(l10n.playlistM3uReportUnresolved(2)), findsOneWidget);
    final first = t.getTopLeft(find.text('Line 4: https://x/y.mp3')).dy;
    final second = t.getTopLeft(find.text('Line 9: /sdcard/a.wma')).dy;
    expect(first, lessThan(second));
    expect(find.text(l10n.playlistM3uReportSkipped(2)), findsNothing);
    expect(find.text(l10n.playlistM3uReportNoBase(2)), findsNothing);
  });

  testWidgets('not-scanned lines only in their own group', (t) async {
    await _pump(t, _result(problems: _lines(M3uProblemKind.notScanned, 2)));
    expect(find.text(l10n.playlistM3uReportSkipped(2)), findsOneWidget);
    expect(find.text(l10n.playlistM3uReportUnresolved(2)), findsNothing);
    expect(find.text('Line 1: notScanned-0.mp3'), findsOneWidget);
  });

  testWidgets('no-base-folder lines only in their own group', (t) async {
    await _pump(t, _result(problems: _lines(M3uProblemKind.noBaseFolder, 3)));
    expect(find.text(l10n.playlistM3uReportNoBase(3)), findsOneWidget);
    expect(find.text(l10n.playlistM3uReportUnresolved(3)), findsNothing);
    expect(find.text(l10n.playlistM3uReportSkipped(3)), findsNothing);
  });

  testWidgets('each group counts its own lines and "more" separately', (
    t,
  ) async {
    final problems = [
      ..._lines(M3uProblemKind.unresolved, 7),
      ..._lines(M3uProblemKind.notScanned, 6, from: 20),
      ..._lines(M3uProblemKind.noBaseFolder, 2, from: 40),
    ];
    await _pump(t, _result(problems: problems), width: 400);
    expect(find.text(l10n.playlistM3uReportUnresolved(7)), findsOneWidget);
    expect(find.text(l10n.playlistM3uReportMore(2)), findsOneWidget);
    expect(find.text(l10n.playlistM3uReportMore(1)), findsOneWidget);
    expect(find.text(l10n.playlistM3uReportNoBase(2)), findsOneWidget);
  });

  testWidgets('no help icon anywhere', (t) async {
    await _pump(
      t,
      _result(
        notInLibrary: 1,
        problems: [
          ..._lines(M3uProblemKind.unresolved, 1),
          ..._lines(M3uProblemKind.notScanned, 1, from: 5),
          ..._lines(M3uProblemKind.noBaseFolder, 1, from: 9),
        ],
      ),
    );
    // A help affordance would be a tappable control with a help tooltip.
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('a long line is cut to 300 graphemes + ellipsis; control and '
      'direction characters become spaces', (t) async {
    final long = 'x' * 400;
    final text = 'a\u202Eb\u0007c';
    await _pump(
      t,
      _result(
        problems: [
          M3uProblemLine(line: 1, text: long, kind: M3uProblemKind.unresolved),
          M3uProblemLine(line: 2, text: text, kind: M3uProblemKind.unresolved),
        ],
      ),
    );
    expect(find.text('Line 1: ${'x' * 300}…'), findsOneWidget);
    expect(find.text('Line 2: a b c'), findsOneWidget);
    expect(cleanReportLine('é' * 300), 'é' * 300);
  });

  testWidgets('truncated note is visible only when truncated', (t) async {
    await _pump(t, _result(truncated: true));
    expect(find.text(l10n.m3uReportTruncated(m3uMaxPathLines)), findsOneWidget);
    await _pump(t, _result());
    expect(find.text(l10n.m3uReportTruncated(m3uMaxPathLines)), findsNothing);
  });

  testWidgets('Close pops false, Open playlist pops true', (t) async {
    var popped = await _pump(t, _result());
    await t.tap(find.text(l10n.playlistClose));
    await t.pumpAndSettle();
    expect(popped, [false]);
    popped = await _pump(t, _result());
    await t.tap(find.text(l10n.playlistM3uOpenPlaylist));
    await t.pumpAndSettle();
    expect(popped, [true]);
  });

  testWidgets('Vietnamese texts', (t) async {
    await _pump(
      t,
      _result(notInLibrary: 2, problems: _lines(M3uProblemKind.notScanned, 1)),
      locale: 'vi',
    );
    final vi = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(find.text('Đã nhập playlist'), findsOneWidget);
    expect(find.text(vi.playlistM3uReportSkipped(1)), findsOneWidget);
    expect(find.text('Mở playlist'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);
  });

  for (final (width, scale, dark) in [
    (360.0, 1.5, false),
    (360.0, 2.0, true),
    (1280.0, 2.0, false),
  ]) {
    testWidgets('no overflow at $width px, $scale x text, '
        '${dark ? 'dark' : 'light'}', (t) async {
      await _pump(
        t,
        _result(
          notInLibrary: 2,
          truncated: true,
          problems: [
            ..._lines(M3uProblemKind.unresolved, 7),
            ..._lines(M3uProblemKind.notScanned, 2, from: 20),
            ..._lines(M3uProblemKind.noBaseFolder, 2, from: 40),
          ],
        ),
        width: width,
        textScale: scale,
        theme: dark ? ThemeData.dark() : ThemeData.light(),
      );
      expect(t.takeException(), isNull);
      expect(find.text(l10n.playlistM3uOpenPlaylist), findsOneWidget);
    });
  }
}
