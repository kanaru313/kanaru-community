import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Loading look of the info body: six grey bars of different lengths that
/// pulse slowly (still when animations are off). Hidden from screen readers.
class SongInfoSkeleton extends StatefulWidget {
  const SongInfoSkeleton({super.key});

  static const int bars = 6;

  @override
  State<SongInfoSkeleton> createState() => _SongInfoSkeletonState();
}

class _SongInfoSkeletonState extends State<SongInfoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: KMotion.focusPulse,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _started) {
      _pulse.stop();
      _started = false;
    } else if (!still && !_started) {
      _pulse.repeat(reverse: true);
      _started = true;
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
    const widths = [0.9, 0.6, 0.75, 0.5, 0.8, 0.4];
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
        child: Padding(
          padding: const EdgeInsets.all(KSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < SongInfoSkeleton.bars; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: KSpace.x4),
                  child: FractionallySizedBox(
                    widthFactor: widths[i],
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: KRadius.sm,
                      ),
                      child: const SizedBox(height: 20),
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
