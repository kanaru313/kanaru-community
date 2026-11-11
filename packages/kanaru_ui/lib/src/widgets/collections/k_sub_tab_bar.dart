import 'package:material_ui/material_ui.dart';

import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// Row of text tabs that scrolls sideways, with a primary underline under the
/// selected tab, which scrolls to the centre when selected.
///
/// A page that replaces the bar (switching lists) passes the old row's
/// [initialOffset], learnt from [onOffsetChanged], so the row starts where it
/// was and only then glides to the new centre.
class KSubTabBar extends StatefulWidget {
  const KSubTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.initialOffset = 0,
    this.onOffsetChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double initialOffset;

  /// Reports the row's scroll offset whenever it changes.
  final ValueChanged<double>? onOffsetChanged;

  @override
  State<KSubTabBar> createState() => _KSubTabBarState();
}

class _KSubTabBarState extends State<KSubTabBar> {
  late final ScrollController _controller = ScrollController(
    initialScrollOffset: widget.initialOffset,
  )..addListener(_report);
  late List<GlobalKey> _keys = _newKeys();

  List<GlobalKey> _newKeys() =>
      List.generate(widget.labels.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _centreAfterFrame();
  }

  @override
  void didUpdateWidget(KSubTabBar old) {
    super.didUpdateWidget(old);
    if (old.labels.length != widget.labels.length) _keys = _newKeys();
    if (old.selectedIndex != widget.selectedIndex ||
        old.labels.length != widget.labels.length) {
      _centreAfterFrame();
    }
  }

  void _report() => widget.onOffsetChanged?.call(_controller.offset);

  void _centreAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = widget.selectedIndex;
      final tabContext = index >= 0 && index < _keys.length
          ? _keys[index].currentContext
          : null;
      if (tabContext == null) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      Scrollable.ensureVisible(
        tabContext,
        alignment: 0.5,
        duration: reduce ? Duration.zero : KMotion.normal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
      child: Row(
        children: [
          for (var i = 0; i < widget.labels.length; i++)
            Semantics(
              key: _keys[i],
              button: true,
              selected: i == widget.selectedIndex,
              inMutuallyExclusiveGroup: true,
              child: InkWell(
                borderRadius: KRadius.sm,
                onTap: () => widget.onSelected(i),
                child: SizedBox(
                  height: KLayout.minTarget,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: KSpace.x4),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.labels[i],
                              maxLines: 1,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: i == widget.selectedIndex
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: i == widget.selectedIndex
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: KMotion.fast,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i == widget.selectedIndex
                                ? scheme.primary
                                : const Color(0x00000000),
                            borderRadius: KRadius.full,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
