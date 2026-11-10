import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/spring_to_rest.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// The animation as it was before the design system snapped to the end: it
/// stops within 1e-3 of the target and keeps that value.
TickerFuture _nonSnapping(
  BuildContext context,
  AnimationController c,
  double target,
  SpringDescription spring, {
  double velocity = 0,
}) => c.animateWith(SpringSimulation(spring, c.value, target, velocity));

void main() {
  for (final (name, spring) in [
    ('gentle', KSpring.gentle),
    ('snappy', KSpring.snappy),
    ('bouncy', KSpring.bouncy),
  ]) {
    for (final target in [0.0, 1.0]) {
      testWidgets('$name ends exactly on $target', (tester) async {
        late AnimationController c;
        late BuildContext ctx;
        await tester.pumpWidget(
          _Host(
            onReady: (context, controller) {
              ctx = context;
              c = controller;
            },
          ),
        );
        c.value = 1 - target;
        final done = animateSpringTo(
          ctx,
          c,
          target,
          spring,
          animate: _nonSnapping,
        );
        await tester.pumpAndSettle();
        await done;
        expect(c.value, target);
      });
    }
  }
}

class _Host extends StatefulWidget {
  const _Host({required this.onReady});
  final void Function(BuildContext, AnimationController) onReady;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final c = AnimationController.unbounded(vsync: this);
  @override
  void initState() {
    super.initState();
    widget.onReady(context, c);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
