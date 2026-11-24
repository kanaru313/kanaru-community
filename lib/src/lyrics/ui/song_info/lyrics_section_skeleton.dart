import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Loading look of the lyrics group: a source bar and three text bars that
/// pulse slowly (still when animations are off). Hidden from screen readers.
class LyricsSectionSkeleton extends StatefulWidget {
  const LyricsSectionSkeleton({super.key});

  @override
  State<LyricsSectionSkeleton> createState() => _LyricsSectionSkeletonState();
}

class _LyricsSectionSkeletonState extends State<LyricsSectionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: KMotion.focusPulse,
  );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _running) {
      _pulse.stop();
      _running = false;
    } else if (!still && !_running) {
      _pulse.repeat(reverse: true);
      _running = true;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    const widths = [0.5, 0.9, 0.7, 0.8];
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
        child: Padding(
          padding: const EdgeInsets.all(KSpace.x4),
          child: Column(
            children: [
              for (final w in widths)
                Padding(
                  padding: const EdgeInsets.only(bottom: KSpace.x3),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: w,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: KRadius.sm,
                        ),
                        child: const SizedBox(height: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
