import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_focus_ring.dart';
import 'k_inset_shape.dart';

/// Body of a `SelectionRow` with `action: true` or `running: true`: a button
/// that does something at once, never a choice (no mark, no selected state).
/// Touch shells: a 64 dp card with the detail under the title. Desktop: the
/// dense 40 / 36 row with the detail on the same line, right. Built only by
/// `SelectionRow`.
class SelectionActionRow extends StatefulWidget {
  const SelectionActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.disabledReason,
    required this.enabled,
    required this.opensMore,
    required this.running,
    required this.autofocus,
    required this.hint,
    required this.onTap,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final String? disabledReason;
  final bool enabled;
  final bool opensMore;
  final bool running;
  final bool autofocus;
  final String? hint;
  final VoidCallback? onTap;

  @override
  State<SelectionActionRow> createState() => _SelectionActionRowState();
}

class _SelectionActionRowState extends State<SelectionActionRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final reason = widget.disabledReason;
    final active = widget.enabled && reason == null && widget.onTap != null;
    final radius = desktop ? KRadius.xs : KRadius.lg;
    // Dense geometry of KLayout: 40 hit area, 36 visible shape, centred.
    final band = desktop
        ? (KLayout.dropdownRowHeight - KLayout.dropdownRowVisible) / 2
        : 0.0;
    final onCard = widget.running ? scheme.onPrimaryContainer : null;
    final fill = widget.running
        ? scheme.primaryContainer
        : (desktop || widget.opensMore ? null : scheme.surfaceContainerHigh);
    final outlined = widget.opensMore && !desktop;
    final titleStyle = (desktop ? text.bodyMedium : text.titleMedium)?.copyWith(
      fontWeight: desktop && !widget.opensMore && !widget.running
          ? FontWeight.w500
          : FontWeight.w700,
      color: widget.opensMore && desktop ? scheme.primary : onCard,
    );
    final detailStyle = text.bodySmall?.copyWith(
      color: onCard ?? scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final Widget? detail = reason != null ? Text(reason) : widget.subtitle;
    final titleWidget = DefaultTextStyle.merge(
      style: titleStyle,
      child: widget.title,
    );
    final detailWidget = detail == null
        ? null
        : DefaultTextStyle.merge(
            style: detailStyle,
            textAlign: desktop ? TextAlign.end : null,
            child: detail,
          );
    final minHeight = desktop
        ? (widget.running ? 48.0 : KLayout.dropdownRowHeight)
        : 64.0;
    return MergeSemantics(
      child: Semantics(
        container: true,
        button: true,
        enabled: active,
        hint: widget.hint,
        child: Opacity(
          opacity: active ? 1 : 0.38,
          child: Stack(
            children: [
              Positioned.fill(
                top: band,
                bottom: band,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: fill,
                    shape: outlined
                        ? RoundedRectangleBorder(
                            borderRadius: radius,
                            side: BorderSide(color: scheme.outlineVariant),
                          )
                        : KShape.of(radius),
                  ),
                ),
              ),
              Positioned.fill(
                top: band,
                bottom: band,
                child: IgnorePointer(
                  child: KFocusRing(
                    // Rows keep the tint as focus mark; the running card
                    // draws the ring (the card is the focus target).
                    focused: _focused && widget.running,
                    radius: radius,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: KInsetShape(KShape.of(radius), band),
                  hoverColor: scheme.onSurface.withValues(alpha: 0.08),
                  focusColor: widget.running
                      ? const Color(0x00000000)
                      : scheme.onSurface.withValues(alpha: 0.10),
                  highlightColor: scheme.onSurface.withValues(alpha: 0.10),
                  autofocus: widget.autofocus,
                  canRequestFocus: active,
                  onFocusChange: (v) => setState(() => _focused = v),
                  onTap: active ? widget.onTap : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: desktop ? KSpace.x3 : KSpace.x4,
                        vertical: KSpace.x2,
                      ),
                      child: Row(
                        children: [
                          if (widget.leading != null) ...[
                            IconTheme.merge(
                              data: IconThemeData(
                                color: onCard ?? scheme.primary,
                                size: desktop ? KIconSize.sm : KIconSize.md,
                              ),
                              child: widget.leading!,
                            ),
                            SizedBox(width: desktop ? KSpace.x3 : KSpace.x4),
                          ],
                          Expanded(
                            child: desktop
                                ? Row(
                                    children: [
                                      Flexible(child: titleWidget),
                                      if (detailWidget != null) ...[
                                        const SizedBox(width: KSpace.x3),
                                        Expanded(child: detailWidget),
                                      ],
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [titleWidget, ?detailWidget],
                                  ),
                          ),
                          if (widget.running) ...[
                            const SizedBox(width: KSpace.x2),
                            Icon(
                              KIcons.chevronRight,
                              size: KIconSize.md,
                              color: onCard,
                            ),
                          ],
                        ],
                      ),
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
