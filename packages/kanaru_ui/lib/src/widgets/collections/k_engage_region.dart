import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_motion.dart';

/// Tells its [builder] whether the pointer is over the region or focus is
/// inside it ("engaged"). Cards use it to show their ⋮ button on desktop.
class KEngageRegion extends StatefulWidget {
  const KEngageRegion({super.key, required this.builder});

  final Widget Function(BuildContext context, bool engaged) builder;

  @override
  State<KEngageRegion> createState() => _KEngageRegionState();
}

class _KEngageRegionState extends State<KEngageRegion> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) => setState(() => _focused = v),
      child: widget.builder(context, _hovered || _focused),
    ),
  );
}

/// A button laid over a corner of a card: always visible on the mobile
/// shell, on hover or focus on desktop (hidden, it ignores the pointer but
/// stays focusable so Tab reveals it). Sits on a soft round backing so it
/// reads over a cover.
class KCardCorner extends StatelessWidget {
  const KCardCorner({super.key, required this.engaged, required this.child});

  final bool engaged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = FormFactor.of(context) == FormFactor.mobile || engaged;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: KMotion.fast,
      child: IgnorePointer(
        ignoring: !visible,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.78),
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }
}
