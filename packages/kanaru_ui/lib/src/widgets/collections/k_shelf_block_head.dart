part of 'k_shelf_block.dart';

/// Head of a [KShelfBlock]: icon, title, count, see-all button, chevron.
class _Head extends StatefulWidget {
  const _Head({
    required this.title,
    required this.icon,
    required this.count,
    required this.collapsed,
    required this.onToggle,
    required this.onSeeAll,
    required this.seeAllLabel,
    required this.duration,
  });

  final String title;
  final IconData icon;
  final int count;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;
  final Duration duration;

  @override
  State<_Head> createState() => _HeadState();
}

class _HeadState extends State<_Head> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  void _set(VoidCallback change) {
    if (mounted) setState(change);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chevronColor = _hovered ? scheme.onSurface : scheme.onSurfaceVariant;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => _set(() => _hovered = v),
      onShowFocusHighlight: (v) => _set(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onToggle();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.onToggle,
        onTapDown: (_) => _set(() => _pressed = true),
        onTapUp: (_) => _set(() => _pressed = false),
        onTapCancel: () => _set(() => _pressed = false),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: KRadius.lg,
            border: _focused
                ? Border.all(color: scheme.primary, width: 2)
                : null,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KLayout.minTarget),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    expanded: !widget.collapsed,
                    label: '${widget.title}, ${widget.count}',
                    onTap: widget.onToggle,
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: KSpace.x4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.icon,
                            size: KIconSize.sm,
                            color: scheme.primary,
                          ),
                          const KGap(KSpace.x2),
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const KGap(KSpace.x2),
                          Expanded(
                            child: Text(
                              '${widget.count}',
                              maxLines: 1,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.onSeeAll != null)
                  KIconButton(
                    icon: KIcons.grid,
                    size: KIconSize.sm,
                    tooltip: widget.seeAllLabel,
                    onPressed: widget.onSeeAll,
                  ),
                ExcludeSemantics(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Opacity(
                        opacity: _pressed ? 0.5 : 1,
                        child: AnimatedRotation(
                          turns: widget.collapsed ? 0.5 : 0,
                          duration: widget.duration,
                          curve: KMotion.emphasized,
                          child: Icon(
                            KIcons.collapse,
                            size: KIconSize.sm,
                            color: chevronColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
