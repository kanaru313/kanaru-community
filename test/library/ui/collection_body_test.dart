import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/collections/collection_parts.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(
  WidgetTester tester,
  AsyncValue<List<int>> async, {
  Size size = const Size(400, 800),
  bool skeleton = true,
  bool round = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => collectionBody<int>(
            context,
            async,
            (items) => Text('rows ${items.length}'),
            skeletonRows: skeleton,
            roundCover: round,
          ),
        ),
      ),
    ),
  );
}

void main() {
  const loading = AsyncLoading<List<int>>();

  testWidgets('first load shows skeleton rows that fill the viewport', (
    tester,
  ) async {
    await _pump(tester, loading);
    final extent = KMediaCard.extentOf(TextScaler.noScaling);
    final cards = tester.widgetList<KMediaCard>(find.byType(KMediaCard));
    expect(cards, isNotEmpty);
    expect(cards.every((c) => c.loading), isTrue);
    expect(cards.length, greaterThanOrEqualTo((800 / extent).floor()));
    expect(
      tester.getSize(find.byType(KMediaCard).first).height,
      closeTo(extent, 0.5),
    );
    expect(find.byType(ClipRRect), findsWidgets);
  });

  testWidgets('count follows the height (800 dp vs 400 dp)', (tester) async {
    await _pump(tester, loading);
    final tall = tester.widgetList(find.byType(KMediaCard)).length;
    await _pump(tester, loading, size: const Size(400, 400));
    await tester.pump();
    final short = tester.widgetList(find.byType(KMediaCard)).length;
    expect(short, lessThan(tall));
  });

  testWidgets('round cover for artists', (tester) async {
    await _pump(tester, loading, round: true);
    expect(find.byType(ClipOval), findsWidgets);
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('grid view (no skeleton) shows nothing while loading', (
    tester,
  ) async {
    await _pump(tester, loading, skeleton: false);
    expect(find.byType(KMediaCard), findsNothing);
  });

  testWidgets('cached data while reloading: rows at once, no skeleton', (
    tester,
  ) async {
    var pending = Completer<List<int>>();
    final provider = FutureProvider<List<int>>((ref) => pending.future);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                captured = ref;
                return collectionBody<int>(
                  context,
                  ref.watch(provider),
                  (items) => Text('rows ${items.length}'),
                  skeletonRows: true,
                );
              },
            ),
          ),
        ),
      ),
    );
    // First load: skeleton.
    expect(find.byType(KMediaCard), findsWidgets);
    pending.complete([1, 2]);
    await tester.pump();
    await tester.pump();
    expect(find.text('rows 2'), findsOneWidget);
    // Reload keeps the value: no skeleton frame.
    pending = Completer<List<int>>();
    captured.invalidate(provider);
    await tester.pump();
    expect(find.text('rows 2'), findsOneWidget);
    expect(find.byType(KMediaCard), findsNothing);
  });

  testWidgets('data replaces the skeleton', (tester) async {
    await _pump(tester, const AsyncData<List<int>>([1]));
    expect(find.text('rows 1'), findsOneWidget);
    expect(find.byType(KMediaCard), findsNothing);
  });

  testWidgets('error keeps the message', (tester) async {
    await _pump(tester, AsyncError<List<int>>('x', StackTrace.empty));
    expect(find.byType(KMediaCard), findsNothing);
    expect(find.text('Could not load the list'), findsOneWidget);
  });
}
