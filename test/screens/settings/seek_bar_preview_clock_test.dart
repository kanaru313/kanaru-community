import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/seek_bar_preview_clock.dart';

/// Owns a [SeekPreviewClock] the way the page does: as its ticker provider,
/// with motion switched by [motion].
class _Host extends StatefulWidget {
  const _Host({required this.motion, required this.onClock});

  final bool motion;
  final ValueChanged<SeekPreviewClock> onClock;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
  late final SeekPreviewClock clock = SeekPreviewClock(vsync: this);

  @override
  void initState() {
    super.initState();
    widget.onClock(clock);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    clock.motionAllowed = widget.motion;
  }

  @override
  void didUpdateWidget(_Host old) {
    super.didUpdateWidget(old);
    clock.motionAllowed = widget.motion;
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<SeekPreviewClock> _pump(
  WidgetTester tester, {
  bool motion = true,
  bool tickers = true,
}) async {
  late SeekPreviewClock clock;
  await tester.pumpWidget(
    TickerMode(
      enabled: tickers,
      child: _Host(motion: motion, onClock: (c) => clock = c),
    ),
  );
  return clock;
}

void main() {
  testWidgets('starts playing at the start position and advances', (
    tester,
  ) async {
    final clock = await _pump(tester);
    expect(clock.playing, isTrue);
    final start = clock.position;
    expect(start, seekPreviewDuration * seekPreviewStart);
    var changes = 0;
    clock.addListener(() => changes++);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(clock.position, greaterThan(start));
    expect(changes, greaterThan(0));
  });

  testWidgets('a long gap between frames moves it by one capped step', (
    tester,
  ) async {
    final clock = await _pump(tester);
    await tester.pump(const Duration(milliseconds: 16));
    final before = clock.position;
    await tester.pump(const Duration(seconds: 30));
    expect(
      clock.position - before,
      lessThanOrEqualTo(const Duration(milliseconds: 50)),
    );
  });

  testWidgets('paused: no frames are scheduled and the position stays', (
    tester,
  ) async {
    final clock = await _pump(tester);
    clock.togglePlaying();
    await tester.pump();
    expect(clock.playing, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
    final at = clock.position;
    await tester.pump(const Duration(seconds: 2));
    expect(clock.position, at);
    clock.togglePlaying();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('covered page (tickers off): no frames, no movement', (
    tester,
  ) async {
    final clock = await _pump(tester, tickers: false);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    final at = clock.position;
    await tester.pump(const Duration(seconds: 2));
    expect(clock.position, at);
  });

  testWidgets('reduced motion: starts paused; Play runs and advances', (
    tester,
  ) async {
    final clock = await _pump(tester, motion: false);
    expect(clock.playing, isFalse);
    expect(clock.tickerActive, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
    final at = clock.position;
    await tester.pump(const Duration(seconds: 2));
    expect(clock.position, at);
    clock.togglePlaying();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(clock.playing, isTrue);
    expect(clock.position, greaterThan(at));
  });

  testWidgets('repeating reduced motion does not pause a preview the user '
      'started', (tester) async {
    final clock = await _pump(tester, motion: false);
    clock.togglePlaying();
    await tester.pump();
    clock.motionAllowed = false;
    expect(clock.playing, isTrue);
  });

  testWidgets('motion turning off after it was on pauses the preview', (
    tester,
  ) async {
    final clock = await _pump(tester);
    expect(clock.playing, isTrue);
    clock.motionAllowed = false;
    expect(clock.playing, isFalse);
  });

  testWidgets('a clock used after it is disposed does not throw', (
    tester,
  ) async {
    final clock = await _pump(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    clock.togglePlaying();
    clock.hold(true);
    clock.seekTo(const Duration(seconds: 3));
    clock.motionAllowed = false;
    expect(tester.takeException(), isNull);
  });

  testWidgets('a held bar stops the clock until it is released', (
    tester,
  ) async {
    final clock = await _pump(tester);
    await tester.pump(const Duration(milliseconds: 16));
    clock.hold(true);
    final at = clock.position;
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40));
    expect(clock.position, at);
    clock.hold(false);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40));
    expect(clock.position, greaterThan(at));
  });

  testWidgets('loops at the end and a seek is clamped to the track', (
    tester,
  ) async {
    final clock = await _pump(tester);
    clock.seekTo(seekPreviewDuration - const Duration(milliseconds: 5));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(clock.position, lessThan(const Duration(seconds: 1)));
    clock.seekTo(seekPreviewDuration * 3);
    expect(clock.position, seekPreviewDuration);
    clock.seekTo(-const Duration(seconds: 3));
    expect(clock.position, Duration.zero);
  });
}
