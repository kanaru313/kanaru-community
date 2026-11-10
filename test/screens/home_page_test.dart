import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline_types.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/scan_controller.dart';
import 'package:kanaru/src/library/state/scan/scan_startup.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/screens/ui/home_page.dart';
import 'package:kanaru/src/screens/ui/settings_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';

void main() {
  group('startup work', () {
    testWidgets('is requested once after the first frame, not on rebuilds', (
      tester,
    ) async {
      var startups = 0;
      await pumpKanaruApp(
        tester,
        overrides: [
          scanStartupWorkProvider.overrideWithValue(() => startups++),
        ],
        settle: false,
      );
      expect(startups, 1);

      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 700);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      expect(startups, 1);
    });

    testWidgets('a scripted scanner is left alone', (tester) async {
      // The harness pins the commands to a no-op implementation and the real
      // startup hook runs: it must not reach for the real controller.
      await pumpKanaruApp(tester);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('with the real controller and setup done, the timers it arms '
        'end with the provider container', (tester) async {
      final timers = <Timer>[];
      var passes = 0;
      final controller = ScanController(
        runPass: (_, _, {required full}) async {
          passes++;
          return ScanOutcome();
        },
        runCoverMisses: (_, _, _) async => ScanOutcome(),
        isSetupDone: () => true,
        collectGarbage: () async {},
        collectCoverFiles: () async {},
        timer: (after, run) {
          final t = Timer(after, run);
          timers.add(t);
          return t;
        },
      );
      final container = ProviderContainer(
        overrides: [
          libraryScanCommandsProvider.overrideWith((ref) {
            ref.onDispose(controller.dispose);
            return controller;
          }),
          scanStatusProvider.overrideWith((ref) => controller.status),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pump();
      expect(passes, 0);
      // The 2 s startup scan and the later collection are armed.
      expect(timers.where((t) => t.isActive), hasLength(2));

      // Going away cancels them (the binding also fails on a pending timer).
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      expect(timers.where((t) => t.isActive), isEmpty);
    });
  });

  group('scan card', () {
    testWidgets('shows progress from the scan status', (tester) async {
      await pumpKanaruApp(
        tester,
        scan: const ScanRunning(phase: ScanPhase.tags, done: 120, total: 242),
      );
      expect(find.text('Scanning the library'), findsOneWidget);
      expect(
        find.text('Reading tags and covers · 120 / 242 songs'),
        findsOneWidget,
      );
    });

    testWidgets('is absent while idle, listing, or after a failure', (
      tester,
    ) async {
      for (final status in <ScanStatus>[
        const ScanIdle(),
        const ScanRunning(phase: ScanPhase.listing, done: 0, total: 0),
        const ScanFailed('permission'),
      ]) {
        await pumpKanaruApp(tester, scan: status);
        expect(find.byType(ProgressNoticeCard), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('settings action', () {
    testWidgets('mobile Home has it and it opens Settings', (tester) async {
      await pumpKanaruApp(tester, width: 400);
      final action = find.byIcon(KIcons.settings);
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('desktop Home leaves it to the sidebar', (tester) async {
      await pumpKanaruApp(tester);
      expect(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.byIcon(KIcons.settings),
        ),
        findsNothing,
      );
    });
  });
}
