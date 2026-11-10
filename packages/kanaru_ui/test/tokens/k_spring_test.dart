import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

class _Host extends StatefulWidget {
  const _Host({required this.onReady, required this.disable});
  final void Function(BuildContext, AnimationController) onReady;
  final bool disable;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController.unbounded(vsync: this);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData(disableAnimations: widget.disable),
    child: Builder(
      builder: (ctx) {
        widget.onReady(ctx, c);
        return const SizedBox();
      },
    ),
  );
}

void main() {
  for (final entry in {
    'snappy': KSpring.snappy,
    'gentle': KSpring.gentle,
    'bouncy': KSpring.bouncy,
  }.entries) {
    testWidgets('${entry.key} settles at the target', (tester) async {
      late BuildContext ctx;
      late AnimationController c;
      await tester.pumpWidget(
        _Host(
          disable: false,
          onReady: (x, k) {
            ctx = x;
            c = k;
          },
        ),
      );
      KSpring.animateTo(ctx, c, 1, entry.value);
      await tester.pumpAndSettle();
      expect(c.value, closeTo(1, 0.001));
    });
  }

  testWidgets('reduced motion jumps to the target', (tester) async {
    late BuildContext ctx;
    late AnimationController c;
    await tester.pumpWidget(
      _Host(
        disable: true,
        onReady: (x, k) {
          ctx = x;
          c = k;
        },
      ),
    );
    KSpring.animateTo(ctx, c, 1, KSpring.bouncy);
    await tester.pump();
    expect(c.value, 1);
  });

  testWidgets('bouncy overshoots the target before settling', (tester) async {
    late BuildContext ctx;
    late AnimationController c;
    await tester.pumpWidget(
      _Host(
        disable: false,
        onReady: (x, k) {
          ctx = x;
          c = k;
        },
      ),
    );
    KSpring.animateTo(ctx, c, 1, KSpring.bouncy);
    var peak = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (c.value > peak) peak = c.value;
    }
    await tester.pumpAndSettle();
    expect(peak, greaterThan(1.0));
    expect(c.value, closeTo(1, 0.001));
  });

  testWidgets('reduced motion: future completes, status is completed', (
    tester,
  ) async {
    late BuildContext ctx;
    late AnimationController c;
    await tester.pumpWidget(
      _Host(
        disable: true,
        onReady: (x, k) {
          ctx = x;
          c = k;
        },
      ),
    );
    var done = false;
    KSpring.animateTo(ctx, c, 0.5, KSpring.gentle).then((_) => done = true);
    await tester.pump();
    expect(c.value, 0.5);
    expect(done, isTrue);
    expect(c.isAnimating, isFalse);
  });

  test('damping ratios', () {
    // bouncy rings more than snappy: lower ratio at the same mass
    double ratio(SpringDescription s) =>
        s.damping / (2 * math.sqrt(s.mass * s.stiffness));
    expect(ratio(KSpring.bouncy), closeTo(0.72, 1e-9));
    expect(ratio(KSpring.snappy), closeTo(0.9, 1e-9));
    expect(ratio(KSpring.gentle), closeTo(1.0, 1e-9));
  });

  testWidgets('animateTo ends exactly on the target', (tester) async {
    late AnimationController c;
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      ctx = context;
      return const SizedBox();
    })));
    c = AnimationController.unbounded(vsync: tester, value: 1);
    addTearDown(c.dispose);
    for (final spring in [KSpring.snappy, KSpring.gentle, KSpring.bouncy]) {
      c.value = 1;
      KSpring.animateTo(ctx, c, 0, spring);
      await tester.pumpAndSettle();
      expect(c.value, 0.0);
      expect(c.isAnimating, isFalse);
    }
  });
}
