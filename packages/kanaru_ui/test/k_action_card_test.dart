import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

KActionCardAction _act(
  String label, {
  bool primary = false,
  VoidCallback? on,
}) => KActionCardAction(label: label, onPressed: on ?? () {}, primary: primary);

Widget _card({
  List<KActionCardAction> actions = const [],
  KActionCardTone tone = KActionCardTone.normal,
  KActionCardCountdown? countdown,
  bool readOnly = false,
  String? subtitle = 'Thêm 3 bài vào hàng đợi',
  String? reason,
}) => Padding(
  padding: const EdgeInsets.all(8),
  child: KActionCard(
    icon: KIcons.info,
    title: 'Cho phép AI thêm bài?',
    subtitle: subtitle,
    reason: reason,
    tone: tone,
    actions: actions,
    countdown: countdown,
    readOnly: readOnly,
  ),
);

String _words(KCountdownLeft left) => switch (left) {
  KCountdownSeconds(:final seconds) => 'Thử lại sau $seconds giây',
  KCountdownMinutes(:final minutes, :final seconds) =>
    'Thử lại sau $minutes phút $seconds giây',
  KCountdownAt() => 'Thử lại lúc',
};

/// A clock the test moves together with `tester.pump`.
class _Clock {
  _Clock(this.start);
  final DateTime start;
  Duration elapsed = Duration.zero;
  DateTime now() => start.add(elapsed);
  Future<void> advance(WidgetTester tester, Duration d) async {
    elapsed += d;
    await tester.pump(d);
  }
}

final _t0 = DateTime(2026, 11, 25, 19, 5);

KActionCardCountdown _countdown(_Clock clock, Duration left) =>
    KActionCardCountdown(
      until: clock.start.add(left),
      labelOf: _words,
      readyAnnouncement: 'Có thể thử lại',
      now: clock.now,
    );

void main() {
  testWidgets('two actions split the width', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_card(actions: [_act('Từ chối'), _act('Cho phép', primary: true)])),
    );
    final a = tester.getRect(find.widgetWithText(OutlinedButton, 'Từ chối'));
    final b = tester.getRect(find.widgetWithText(FilledButton, 'Cho phép'));
    expect(a.width, closeTo(b.width, 0.01));
    final card = tester.getRect(find.byType(KActionCard));
    expect(a.left - card.left, closeTo(card.right - b.right, 0.01));
    expect(a.top, b.top);
  });

  testWidgets('one action sits at the end', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(actions: [_act('Thử lại')])));
    final button = tester.getRect(
      find.widgetWithText(OutlinedButton, 'Thử lại'),
    );
    final card = tester.getRect(find.byType(KActionCard));
    expect(button.width, lessThan(card.width / 2));
    expect(card.right - button.right, closeTo(12, 0.01));
    // On its own row, under the text.
    expect(
      button.top,
      greaterThan(tester.getRect(find.text('Thêm 3 bài vào hàng đợi')).bottom),
    );
  });

  testWidgets('buttons are 40 on mobile and compact on desktop', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(actions: [_act('Thử lại')])));
    expect(tester.getSize(find.byType(OutlinedButton)).height, 40);
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_card(actions: [_act('Thử lại')])));
    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      KLayout.compactButton,
    );
  });

  testWidgets('read-only card has no live actions and no ticker', (
    tester,
  ) async {
    final clock = _Clock(_t0);
    await tester.pumpWidget(
      host(
        _card(
          actions: [_act('Thử lại')],
          countdown: _countdown(clock, const Duration(seconds: 28)),
          readOnly: true,
          tone: KActionCardTone.error,
        ),
      ),
    );
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    // No timer is armed: the binding fails the test at its end if one is.
  });

  testWidgets('finished card shows no buttons', (tester) async {
    await tester.pumpWidget(
      host(_card(actions: [_act('Thử lại')], tone: KActionCardTone.finished)),
    );
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets(
    'countdown labels: 28 s, 1 phút 30 giây, Thử lại lúc HH:MM from 1 h',
    (tester) async {
      final seen = <KCountdownLeft>[];
      KActionCardCountdown spy(Duration left) => KActionCardCountdown(
        until: _t0.add(left),
        labelOf: (l) {
          seen.add(l);
          return _words(l);
        },
        readyAnnouncement: 'Có thể thử lại',
        now: () => _t0,
      );

      for (final (left, want) in [
        (const Duration(seconds: 28), const KCountdownSeconds(28)),
        (const Duration(seconds: 90), const KCountdownMinutes(1, 30)),
        (
          const Duration(seconds: 59, milliseconds: 100),
          const KCountdownMinutes(1, 0),
        ),
        (
          const Duration(hours: 2),
          KCountdownAt(_t0.add(const Duration(hours: 2))),
        ),
      ]) {
        seen.clear();
        await tester.pumpWidget(
          host(_card(actions: [_act('Thử lại')], countdown: spy(left))),
        );
        expect(seen.last, want);
        await tester.pumpWidget(const SizedBox());
      }
      expect(KCountdownAt(_t0.add(const Duration(hours: 2))).until.hour, 21);
      expect(KCountdownAt(_t0.add(const Duration(hours: 2))).until.minute, 5);
    },
  );

  testWidgets('countdown disables the action until the time (fake clock)', (
    tester,
  ) async {
    final clock = _Clock(_t0);
    var pressed = 0;
    final messages = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (m) async {
        messages.add(m);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(
            SystemChannels.accessibility,
            null,
          ),
    );
    int announced() =>
        messages.where((m) => m.toString().contains('Có thể thử lại')).length;
    await tester.pumpWidget(
      host(
        _card(
          actions: [_act('Thử lại', on: () => pressed++)],
          countdown: _countdown(clock, const Duration(seconds: 3)),
        ),
      ),
    );
    final button = find.byType(OutlinedButton);
    expect(find.text('Thử lại sau 3 giây'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);

    await clock.advance(tester, const Duration(seconds: 1));
    expect(find.text('Thử lại sau 2 giây'), findsOneWidget);
    await clock.advance(tester, const Duration(seconds: 1));
    expect(find.text('Thử lại sau 1 giây'), findsOneWidget);
    expect(messages, isEmpty, reason: 'nothing is announced while counting');

    await clock.advance(tester, const Duration(seconds: 1));
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    expect(pressed, 0, reason: 'nothing is sent by itself');
    expect(announced(), 1, reason: 'announced once when ready');

    await tester.tap(button);
    expect(pressed, 1);
    await clock.advance(tester, const Duration(seconds: 5));
    expect(announced(), 1);
  });

  testWidgets('from an hour the label does not tick every second', (
    tester,
  ) async {
    final clock = _Clock(_t0);
    var built = 0;
    final countdown = KActionCardCountdown(
      until: _t0.add(const Duration(hours: 2)),
      labelOf: (l) {
        built++;
        return _words(l);
      },
      readyAnnouncement: 'Có thể thử lại',
      now: clock.now,
    );
    await tester.pumpWidget(
      host(_card(actions: [_act('Thử lại')], countdown: countdown)),
    );
    final before = built;
    await clock.advance(tester, const Duration(minutes: 30));
    expect(built, before);
  });

  testWidgets('ticker disposed with the widget', (tester) async {
    final clock = _Clock(_t0);
    await tester.pumpWidget(
      host(
        _card(
          actions: [_act('Thử lại')],
          countdown: _countdown(clock, const Duration(seconds: 28)),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    // The test binding fails the test if a timer is still pending here.
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticker stops when the countdown is removed', (tester) async {
    final clock = _Clock(_t0);
    await tester.pumpWidget(
      host(
        _card(
          actions: [_act('Thử lại')],
          countdown: _countdown(clock, const Duration(seconds: 28)),
        ),
      ),
    );
    await tester.pumpWidget(host(_card(actions: [_act('Thử lại')])));
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('error tone uses errorContainer', (tester) async {
    await tester.pumpWidget(host(_card(tone: KActionCardTone.error)));
    final scheme = Theme.of(tester.element(find.byType(KActionCard)))
        .colorScheme;
    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(KActionCard),
        matching: find.byType(DecoratedBox),
      ),
    );
    final colors = boxes
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>()
        .map((d) => d.color);
    expect(colors, contains(scheme.errorContainer));
    expect(colors, isNot(contains(scheme.surfaceContainerHigh)));
  });

  testWidgets('error card is a live region unless read-only', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_card(tone: KActionCardTone.error)));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(RegExp('^Cho phép AI thêm bài')))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    await tester.pumpWidget(
      host(_card(tone: KActionCardTone.error, readOnly: true)),
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(RegExp('^Cho phép AI thêm bài')))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isFalse,
    );
    handle.dispose();
  });

  testWidgets('finished card is dimmed to 0.62', (tester) async {
    await tester.pumpWidget(host(_card(tone: KActionCardTone.finished)));
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(KActionCard),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.62);
  });

  testWidgets('shows subtitle and reason without cutting them', (tester) async {
    useWindow(tester, const Size(300, 800));
    const reason = 'Hết hạn mức của nhà cung cấp, thử lại sau ít phút nữa nhé.';
    await tester.pumpWidget(
      host(
        _card(
          reason: reason,
          subtitle: 'Một dòng phụ khá dài để xuống hàng trong thẻ hẹp',
        ),
      ),
    );
    expect(find.text(reason), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at 200 % text with two long buttons', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 900));
    await tester.pumpWidget(
      host(
        _card(
          actions: [
            _act('Cuộc trò chuyện mới'),
            _act('Cho phép', primary: true),
          ],
          reason: 'Một lý do khá dài',
        ),
        textScale: 2.0,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finished card with a countdown runs no clock', (tester) async {
    final clock = _Clock(_t0);
    await tester.pumpWidget(
      host(
        _card(
          tone: KActionCardTone.finished,
          actions: [_act('Thử lại')],
          countdown: _countdown(clock, const Duration(seconds: 30)),
        ),
      ),
    );
    expect(find.byType(OutlinedButton), findsNothing);
    // A pending timer would fail the test at teardown.
    await tester.pump(const Duration(seconds: 2));
  });
}
