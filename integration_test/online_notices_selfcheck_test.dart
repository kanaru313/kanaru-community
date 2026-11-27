import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/shell/ui/playback_notice_listener.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Device check of the online playback notices (snack bars with Thử lại /
/// Mở cài đặt, the rate-limit countdown) and of `PageHeader(shellActions:
/// false)`. Nothing in the app emits these notices yet and no online page uses
/// the header opt-out, so the test pumps the real app theme, the real
/// `showPlaybackNotice` and a `PageHeader` inside a `PageHeaderScope` with
/// stand-in shell buttons, and does not start the app. It asserts texts and
/// the enabled state of the action (semantics); screenshots are for comparing
/// with `mockups/screens/00-online-parts.md` (part 5) and `10-online.md` by
/// eye and never fail the test. Linux writes
/// `/tmp/kanaru-online-foundation/shots/<name>.png`; other platforms print the
/// PNG as `KSHOT <name> <chunk index> <base64>` lines.
///
/// Run through the main checkout's `main-build.sh`:
/// `flutter test integration_test/online_notices_selfcheck_test.dart -d <device>`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final vi = AppLocalizationsVi();
  final tag = Platform.isLinux ? 'linux' : 'phone';

  /// A hand-moved monotonic clock for the countdown.
  var clockTime = Duration.zero;
  Duration clock() => clockTime;

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 400));
    try {
      final view = tester.binding.renderViews.first;
      final layer = view.debugLayer! as OffsetLayer;
      final bytes = await tester.runAsync(() async {
        final image = await layer.toImage(Offset.zero & view.size);
        return (await image.toByteData(format: ui.ImageByteFormat.png))!;
      });
      final png = bytes!.buffer.asUint8List();
      if (Platform.isLinux) {
        final dir = Directory('/tmp/kanaru-online-foundation/shots')
          ..createSync(recursive: true);
        File('${dir.path}/$tag-$name.png').writeAsBytesSync(png);
      } else {
        final b64 = base64Encode(png);
        const chunk = 2000;
        for (var i = 0; i * chunk < b64.length; i++) {
          final end = (i + 1) * chunk;
          final part = b64.substring(
            i * chunk,
            end > b64.length ? b64.length : end,
          );
          // ignore: avoid_print
          print('KSHOT $tag-$name $i $part');
        }
        // ignore: avoid_print
        print('KSHOT $tag-$name END');
      }
    } on Object catch (e) {
      debugPrint('screenshot $name failed: $e');
    }
  }

  /// Pumps a page with a "show" button that raises [notice].
  Future<void> pumpPage(
    WidgetTester tester,
    PlaybackNotice notice, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Size size = const Size(412, 800),
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
                    showPlaybackNotice(context, notice, now: clock),
                child: const Text('show'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/plugins/p/:id',
          builder: (context, _) =>
              const Scaffold(body: Center(child: Text('plugin page'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    clockTime = Duration.zero;
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('vi'),
        theme: buildKanaruTheme(brightness: brightness),
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
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder action(String label) => find.widgetWithText(TextButton, label);

  /// Whether the action button is enabled (the snack bar action's semantics
  /// node merges into the bar's, so the button's own callback is read).
  bool enabled(WidgetTester tester, String label) =>
      tester.widget<TextButton>(action(label)).onPressed != null;

  const modes = [Brightness.light, Brightness.dark];
  String mode(Brightness b) => b == Brightness.light ? 'light' : 'dark';

  testWidgets('offline notice with Thử lại', (tester) async {
    final semantics = tester.ensureSemantics();
    var retried = 0;
    for (final b in modes) {
      await pumpPage(
        tester,
        PausedOffline(retry: () => retried++),
        brightness: b,
      );
      expect(find.text(vi.playbackNoticePausedOffline), findsOneWidget);
      expect(enabled(tester, vi.playbackNoticeRetry), true);
      await shot(tester, 'offline-${mode(b)}');
    }
    await tester.tap(action(vi.playbackNoticeRetry));
    expect(retried, 1);
    semantics.dispose();
  });

  testWidgets('rate limit counts down, then Thử lại lights up', (tester) async {
    final semantics = tester.ensureSemantics();
    var retried = 0;
    PausedRateLimited notice() => PausedRateLimited(
      sourceName: 'Audius',
      pauseLength: const Duration(seconds: 60),
      remaining: const Duration(seconds: 48),
      retry: () => retried++,
    );
    for (final b in modes) {
      await pumpPage(tester, notice(), brightness: b);
      final counting = vi.playbackNoticePausedRateLimited(
        'Audius',
        vi.playbackNoticePauseMinutes(1),
        '0:48',
      );
      expect(find.text(counting), findsOneWidget);
      expect(enabled(tester, vi.playbackNoticeRetry), false);
      await shot(tester, 'ratelimit-counting-${mode(b)}');

      clockTime += const Duration(seconds: 48);
      await tester.pump(const Duration(seconds: 48));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(vi.playbackNoticePauseEnded('Audius')), findsOneWidget);
      expect(enabled(tester, vi.playbackNoticeRetry), true);
      await shot(tester, 'ratelimit-ended-${mode(b)}');
    }
    await tester.tap(action(vi.playbackNoticeRetry));
    expect(retried, 1);
    semantics.dispose();
  });

  testWidgets('needs config opens the plugin settings', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final b in modes) {
      await pumpPage(
        tester,
        const PausedNeedsConfig(sourceName: 'Audius', installId: 'audius'),
        brightness: b,
      );
      expect(
        find.text(vi.playbackNoticePausedNeedsConfig('Audius')),
        findsOneWidget,
      );
      expect(enabled(tester, vi.playbackNoticeOpenSettings), true);
      await shot(tester, 'needsconfig-${mode(b)}');
    }
    await tester.tap(action(vi.playbackNoticeOpenSettings));
    await tester.pumpAndSettle();
    expect(find.text('plugin page'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('one track refused (403) with Thử lại', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final b in modes) {
      await pumpPage(
        tester,
        TrackFailed(
          'Blinding Lights',
          sourceName: 'Audius',
          cause: RemoteFailureCause.linkRefused,
          code: '403',
          retry: () {},
        ),
        brightness: b,
      );
      expect(
        find.text(
          vi.playbackNoticeFailedLink('Blinding Lights', 'Audius', '403'),
        ),
        findsOneWidget,
      );
      expect(enabled(tester, vi.playbackNoticeRetry), true);
      await shot(tester, 'track403-${mode(b)}');
    }
    semantics.dispose();
  });

  testWidgets('local notice has no action', (tester) async {
    for (final b in modes) {
      await pumpPage(tester, const QueueEnd(), brightness: b);
      expect(find.text(vi.playbackNoticeQueueEnd), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget); // only "show"
      await shot(tester, 'queueend-${mode(b)}');
    }
  });

  testWidgets('notices at 200 % text wrap', (tester) async {
    await pumpPage(tester, PausedOffline(retry: () {}), textScale: 2);
    expect(find.text(vi.playbackNoticePausedOffline), findsOneWidget);
    expect(action(vi.playbackNoticeRetry), findsOneWidget);
    await shot(tester, 'offline-200');
    await pumpPage(
      tester,
      TrackFailed(
        'Blinding Lights',
        sourceName: 'Audius',
        cause: RemoteFailureCause.linkRefused,
        code: '403',
        retry: () {},
      ),
      textScale: 2,
    );
    await shot(tester, 'track403-200');
    await pumpPage(
      tester,
      PausedRateLimited(
        sourceName: 'Audius',
        pauseLength: const Duration(seconds: 60),
        remaining: const Duration(seconds: 48),
        retry: () {},
      ),
      textScale: 2,
    );
    await shot(tester, 'ratelimit-counting-200');
  });

  /// Header page: mobile scope = `[☰] title [✦] [⚙]`, desktop = `🔍` only.
  Widget headerPage({required bool mobile, required bool shellActions}) {
    Widget btn(IconData icon, String tip) =>
        KIconButton(icon: icon, tooltip: tip, onPressed: () {});
    return PageHeaderScope(
      leading: mobile ? btn(KIcons.settings, 'Menu') : null,
      trailing: mobile ? const [] : [btn(KIcons.search, 'Tìm kiếm')],
      rootTrailing: mobile
          ? [btn(KIcons.ai, 'Trợ lý AI'), btn(KIcons.settings, 'Cài đặt')]
          : const [],
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: shellActions ? 'Mặc định' : 'Trực tuyến',
                shellActions: shellActions,
                actions: [btn(KIcons.search, 'Tìm trong nguồn')],
              ),
            ],
          ),
        ),
      ),
    );
  }

  for (final (label, width, mobile) in [
    ('412', 412.0, true),
    ('1200', 1200.0, false),
  ]) {
    for (final b in modes) {
      testWidgets('header at $label ${mode(b)}', (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 300);
        addTearDown(tester.view.reset);
        for (final shellActions in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('vi'),
              theme: buildKanaruTheme(brightness: b),
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: headerPage(mobile: mobile, shellActions: shellActions),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          // The page's own action is always there; the shell's only by default.
          expect(find.semantics.byLabel('Tìm trong nguồn'), findsOneWidget);
          expect(
            find.semantics.byLabel('Trợ lý AI'),
            findsNWidgets(mobile && shellActions ? 1 : 0),
          );
          expect(
            find.semantics.byLabel('Cài đặt'),
            findsNWidgets(mobile && shellActions ? 1 : 0),
          );
          expect(
            find.semantics.byLabel('Tìm kiếm'),
            findsNWidgets(!mobile && shellActions ? 1 : 0),
          );
          // The root page's leading button stays.
          expect(find.semantics.byLabel('Menu'), findsNWidgets(mobile ? 1 : 0));
          await shot(
            tester,
            'header-$label-${shellActions ? 'default' : 'optout'}-${mode(b)}',
          );
        }
        semantics.dispose();
      });
    }
  }

  // Keep the binding referenced: it must be initialised before any test.
  assert(binding.runtimeType.toString().isNotEmpty);
}
