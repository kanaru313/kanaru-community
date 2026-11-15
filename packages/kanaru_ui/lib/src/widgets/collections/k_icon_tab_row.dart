import 'package:material_ui/material_ui.dart';

import '../../tokens/k_icon_size.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// Tabs of a [KSubTabBar] that show an icon each: the selected tab adds its
/// label and sits under a primary underline, the others stay icon only (their
/// tooltip and semantics label keep the name).
///
/// Switching animates over [KMotion.normal]: the label of the old tab
/// collapses and fades while the new one opens, and one underline slides to
/// the new tab. Tab widths are computed from the measured labels, so the
/// underline knows its end rect before the widths finish animating. With
/// reduced motion the change is instant.
class KIconTabRow extends StatelessWidget {
  const KIconTabRow({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
    required this.itemKeys,
  }) : assert(
         labels.length == icons.length && labels.length == itemKeys.length,
       );

  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// One key per tab, for the parent to scroll the selected one into view.
  final List<GlobalKey> itemKeys;

  static const double _gap = KSpace.x2;
  static const double _underline = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.normal;
    final base = Theme.of(context).textTheme.titleSmall!;
    final scaler = MediaQuery.textScalerOf(context);
    final boldStyle = base.copyWith(fontWeight: FontWeight.w700);

    double labelWidth(int i) {
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: boldStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    double tabWidth(int i) =>
        2 * KSpace.x4 +
        KIconSize.sm +
        (i == selectedIndex ? _gap + labelWidth(i) : 0);

    final widths = [for (var i = 0; i < labels.length; i++) tabWidth(i)];
    var left = 0.0;
    for (var i = 0; i < selectedIndex && i < widths.length; i++) {
      left += widths[i];
    }
    final hasSelection = selectedIndex >= 0 && selectedIndex < labels.length;

    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              _Tab(
                key: itemKeys[i],
                label: labels[i],
                icon: icons[i],
                selected: i == selectedIndex,
                width: widths[i],
                duration: duration,
                style: i == selectedIndex ? boldStyle : base,
                color: i == selectedIndex
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
                onTap: () => onSelected(i),
              ),
          ],
        ),
        if (hasSelection)
          AnimatedPositioned(
            duration: duration,
            curve: Curves.ease,
            left: left + KSpace.x4,
            width: widths[selectedIndex] - 2 * KSpace.x4,
            bottom: 0,
            height: _underline,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: KRadius.full,
              ),
            ),
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.width,
    required this.duration,
    required this.style,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final double width;
  final Duration duration;
  final TextStyle style;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: InkWell(
        borderRadius: KRadius.sm,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.ease,
          width: width,
          height: KLayout.minTarget,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: KSpace.x4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: KIconSize.sm, color: color),
                    Padding(
                      padding: const EdgeInsets.only(left: KIconTabRow._gap),
                      child: AnimatedOpacity(
                        duration: duration,
                        opacity: selected ? 1 : 0,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: style.copyWith(color: color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
