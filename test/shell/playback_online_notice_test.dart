import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/shell/ui/playback_notice_listener.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

PausedRateLimited _limited({
  Duration length = const Duration(seconds: 60),
  Duration remaining = const Duration(seconds: 48),
  void Function()? retry,
}) => PausedRateLimited(
  sourceName: 'Audius',
  pauseLength: length,
  remaining: remaining,
  retry: retry ?? () {},
);

/// A hand-moved monotonic clock for the countdown.
class _Clock {
  Duration t = Duration.zero;
  Duration call() => t;
}

/// Moves [clock] and the test clock by [d] together.
Future<void> _advance(WidgetTester tester, _Clock clock, Duration d) async {
  clock.t += d;
  await tester.pump(d);
}

/// Pumps a page whose button shows [notice]; returns nothing, taps go through
/// the finders.
Future<void> _show(
  WidgetTester tester,
  PlaybackNotice notice, {
  double textScale = 1,
  Size size = const Size(400, 800),
  List<RouteBase> routes = const [],
  _Clock? clock,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  showPlaybackNotice(context, notice, now: clock?.call),
              child: const Text('show'),
            ),
          ),
        ),
      ),
      ...routes,
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: buildKanaruTheme(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
  await tester.tap(find.text('show'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  group('notice words', () {
    test('remote track failures', () {
      const link = TrackFailed(
        'Blinding Lights',
        sourceName: 'Audius',
        cause: RemoteFailureCause.linkRefused,
        code: '403',
      );
      expect(
        noticeText(vi, link),
        'Không phát được “Blinding Lights”: Audius không trả link phát (403)',
      );
      expect(
        noticeText(en, link),
        'Could not play “Blinding Lights”: Audius returned no stream link (403)',
      );
      const format = TrackFailed(
        'Song',
        sourceName: 'Audius',
        cause: RemoteFailureCause.formatUnsupported,
      );
      expect(
        noticeText(vi, format),
        'Không phát được “Song”: Kanaru chưa phát được định dạng của Audius',
      );
      expect(
        noticeText(en, format),
        "Could not play “Song”: Kanaru cannot play Audius's format yet",
      );
      const gone = TrackFailed(
        'Song',
        sourceName: 'Audius',
        cause: RemoteFailureCause.gone,
      );
      expect(noticeText(vi, gone), 'Bỏ qua “Song”: không còn trên Audius');
      expect(noticeText(en, gone), 'Skipped “Song”: no longer on Audius');
      const other = TrackFailed(
        'Song',
        cause: RemoteFailureCause.other,
        code: '500',
      );
      expect(noticeText(vi, other), 'Không phát được “Song” (500)');
      expect(noticeText(en, other), 'Could not play “Song” (500)');
      // A cause without what its sentence needs falls back to the plain one.
      const bare = TrackFailed('Song', cause: RemoteFailureCause.gone);
      expect(noticeText(en, bare), 'Could not play “Song”');
    });

    test('paused notices', () {
      final offline = PausedOffline(retry: () {});
      expect(
        noticeText(vi, offline),
        'Không có mạng: chưa phát được bài trực tuyến',
      );
      expect(noticeText(en, offline), 'No network: online tracks cannot play');
      expect(
        noticeText(vi, _limited()),
        'Audius tạm dừng 1 phút (429). Phát tiếp được sau 0:48.',
      );
      expect(
        noticeText(en, _limited()),
        'Audius paused for 1 minute (429). Playback can resume in 0:48.',
      );
      expect(
        noticeText(vi, _limited(remaining: Duration.zero)),
        'Audius đã hết tạm dừng.',
      );
      expect(
        noticeText(en, _limited(remaining: Duration.zero)),
        'Audius is no longer paused.',
      );
      const config = PausedNeedsConfig(sourceName: 'Audius', installId: 'a');
      expect(noticeText(vi, config), 'Audius cần cấu hình trước khi phát.');
      expect(
        noticeText(en, config),
        'Audius needs setting up before it can play.',
      );
      final busy = PausedSourceBusy(sourceName: 'Audius', retry: () {});
      expect(noticeText(vi, busy), 'Audius chưa trả lời: tạm dừng ở bài này.');
      expect(
        noticeText(en, busy),
        'Audius is not answering: paused at this track.',
      );
    });

    test('length and time formatting', () {
      expect(pauseLengthText(vi, const Duration(seconds: 60)), '1 phút');
      expect(pauseLengthText(vi, const Duration(seconds: 90)), '2 phút');
      expect(pauseLengthText(vi, const Duration(seconds: 45)), '45 giây');
      expect(pauseLengthText(en, const Duration(seconds: 60)), '1 minute');
      expect(pauseLengthText(en, const Duration(seconds: 90)), '2 minutes');
      expect(pauseLengthText(en, const Duration(seconds: 1)), '1 second');
      expect(countdownText(const Duration(seconds: 48)), '0:48');
      expect(countdownText(const Duration(seconds: 65)), '1:05');
      expect(countdownText(const Duration(milliseconds: 100)), '0:01');
      expect(countdownText(Duration.zero), '0:00');
    });

    test('only online notices with something to do carry an action', () {
      expect(noticeAction(const TrackFailed('Song')), isNull);
      expect(noticeAction(const FirstTrack()), isNull);
      expect(
        noticeAction(TrackFailed('Song', retry: () {})),
        NoticeAction.retry,
      );
      expect(noticeAction(PausedOffline(retry: () {})), NoticeAction.retry);
      expect(noticeAction(_limited()), NoticeAction.retry);
      expect(
        noticeAction(const PausedNeedsConfig(sourceName: 'A', installId: 'a')),
        NoticeAction.openSettings,
      );
    });
  });

  group('snack bars', () {
    testWidgets('a local notice has no action', (tester) async {
      await _show(tester, const TrackFailed('Song'));
      expect(find.text('Could not play “Song”'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });

    testWidgets('retry runs the callback once', (tester) async {
      var calls = 0;
      await _show(tester, PausedOffline(retry: () => calls++));
      expect(
        find.text('No network: online tracks cannot play'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('a failed track offers retry when the emitter gave one', (
      tester,
    ) async {
      var calls = 0;
      await _show(
        tester,
        TrackFailed(
          'Song',
          sourceName: 'Audius',
          cause: RemoteFailureCause.linkRefused,
          code: '403',
          retry: () => calls++,
        ),
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('needs-config opens the plugin page', (tester) async {
      await _show(
        tester,
        const PausedNeedsConfig(sourceName: 'Audius', installId: 'aud 1'),
        routes: [
          GoRoute(
            path: '/settings/plugins/p/:id',
            builder: (_, state) =>
                Scaffold(body: Text('plugin ${state.pathParameters['id']}')),
          ),
        ],
      );
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(find.text('plugin aud 1'), findsOneWidget);
    });

    testWidgets('countdown: disabled, ticks, enables, then closes', (
      tester,
    ) async {
      var calls = 0;
      final clock = _Clock();
      await _show(
        tester,
        _limited(remaining: const Duration(seconds: 3), retry: () => calls++),
        clock: clock,
      );
      final retry = find.widgetWithText(TextButton, 'Retry');
      expect(
        find.text(
          'Audius paused for 1 minute (429). Playback can resume in 0:03.',
        ),
        findsOneWidget,
      );
      expect(tester.getSemantics(retry), isSemantics(isEnabled: false));
      // Still there well past the usual 4 s.
      await _advance(tester, clock, const Duration(seconds: 2));
      expect(find.textContaining('resume in 0:01'), findsOneWidget);
      await tester.tap(retry, warnIfMissed: false);
      expect(calls, 0);
      await _advance(tester, clock, const Duration(seconds: 1));
      expect(find.text('Audius is no longer paused.'), findsOneWidget);
      expect(tester.getSemantics(retry), isSemantics(isEnabled: true));
      // Closes 4 s after the end.
      await _advance(tester, clock, const Duration(seconds: 3));
      expect(find.byType(SnackBar), findsOneWidget);
      await _advance(tester, clock, const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(calls, 0);
    });

    testWidgets('countdown stays 10 s while counting', (tester) async {
      final clock = _Clock();
      await _show(
        tester,
        _limited(remaining: const Duration(seconds: 30)),
        clock: clock,
      );
      await _advance(tester, clock, const Duration(seconds: 10));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('resume in 0:20'), findsOneWidget);
    });

    testWidgets('retry after the countdown calls back', (tester) async {
      var calls = 0;
      final clock = _Clock();
      await _show(
        tester,
        _limited(remaining: const Duration(seconds: 1), retry: () => calls++),
        clock: clock,
      );
      await _advance(tester, clock, const Duration(seconds: 1));
      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('countdown follows the deadline after a big jump', (
      tester,
    ) async {
      final clock = _Clock();
      await _show(
        tester,
        _limited(remaining: const Duration(seconds: 45)),
        clock: clock,
      );
      final retry = find.widgetWithText(TextButton, 'Retry');
      // One tick fires 30 s late: the text must show the real time left.
      clock.t += const Duration(seconds: 30);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('resume in 0:15'), findsOneWidget);
      expect(tester.getSemantics(retry), isSemantics(isEnabled: false));
      // Another late tick past the deadline enables the button at once.
      clock.t += const Duration(seconds: 60);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Audius is no longer paused.'), findsOneWidget);
      expect(tester.getSemantics(retry), isSemantics(isEnabled: true));
    });

    testWidgets('the ended sentence is a live region, the ticks are not', (
      tester,
    ) async {
      final clock = _Clock();
      await _show(
        tester,
        _limited(remaining: const Duration(seconds: 2)),
        clock: clock,
      );
      // The snack bar itself is already a live region, so look at the
      // sentence's own Semantics node.
      Finder liveSentence(Finder text) => find.ancestor(
        of: text,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.child is Text &&
              w.properties.liveRegion == true,
        ),
      );
      await _advance(tester, clock, const Duration(seconds: 1));
      expect(liveSentence(find.textContaining('resume in 0:01')), findsNothing);
      await _advance(tester, clock, const Duration(seconds: 1));
      expect(
        liveSentence(find.text('Audius is no longer paused.')),
        findsOneWidget,
      );
    });

    testWidgets('a source-busy notice retries once', (tester) async {
      var calls = 0;
      await _show(
        tester,
        PausedSourceBusy(sourceName: 'Audius', retry: () => calls++),
      );
      expect(
        find.text('Audius is not answering: paused at this track.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('a swiped counting bar leaves no timer behind', (tester) async {
      final clock = _Clock();
      await _show(
        tester,
        _limited(remaining: const Duration(seconds: 30)),
        clock: clock,
      );
      await tester.drag(find.byType(SnackBar), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
      // The test ends without a pending periodic timer.
    });

    testWidgets('needs-config without a router shows no action and logs', (
      tester,
    ) async {
      final records = <LogRecord>[];
      final previous = Logger.root.level;
      Logger.root.level = Level.ALL;
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(() async {
        await sub.cancel();
        Logger.root.level = previous;
      });
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPlaybackNotice(
                  context,
                  const PausedNeedsConfig(sourceName: 'Audius', installId: 'a'),
                ),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Audius needs setting up before it can play.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBarAction), findsNothing);
      expect(
        records.where(
          (r) => r.loggerName == 'PlaybackNotice' && r.level == Level.WARNING,
        ),
        hasLength(1),
      );
    });

    testWidgets('a newer notice replaces a counting one', (tester) async {
      await _show(tester, _limited(remaining: const Duration(seconds: 30)));
      final context = tester.element(find.text('show'));
      showPlaybackNotice(context, const QueueEnd());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 40));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('resume in'), findsNothing);
    });

    testWidgets('200 % text: no overflow, retry below the sentence', (
      tester,
    ) async {
      var calls = 0;
      await _show(tester, PausedOffline(retry: () => calls++), textScale: 2);
      expect(tester.takeException(), isNull);
      final text = tester.getRect(
        find.text('No network: online tracks cannot play'),
      );
      final button = tester.getRect(find.widgetWithText(TextButton, 'Retry'));
      expect(button.top, greaterThanOrEqualTo(text.bottom));
      await tester.tap(find.text('Retry'));
      expect(calls, 1);
    });

    testWidgets('countdown at 200 % does not overflow', (tester) async {
      await _show(tester, _limited(), textScale: 2);
      expect(tester.takeException(), isNull);
      final button = tester.getRect(find.widgetWithText(TextButton, 'Retry'));
      final text = tester.getRect(find.textContaining('paused for'));
      expect(button.top, greaterThanOrEqualTo(text.bottom));
    });
  });
}
