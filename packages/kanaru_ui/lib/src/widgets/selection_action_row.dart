import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_focus_ring.dart';
import 'k_inset_shape.dart';
import 'k_start_arrows.dart';
import 'selection_action_row_content.dart';

/// Body of a `SelectionRow.action`: a button that does something at once,
/// never a choice (no mark, no selected state). Arrow keys move focus between
/// start buttons of a `KStartArea`.
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
        focusable: active,
        focused: active ? _focused : null,
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
                    focused: _focused,
                    radius: radius,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              KStartMarker(
                child: Shortcuts(
                  shortcuts: kStartArrowShortcuts(Directionality.of(context)),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: KInsetShape(KShape.of(radius), band),
                      hoverColor: scheme.onSurface.withValues(alpha: 0.08),
                      // Keyboard focus is the ring around the visible shape.
                      focusColor: const Color(0x00000000),
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
                          child: ActionRowContent(
                            leading: widget.leading,
                            title: titleWidget,
                            detail: detailWidget,
                            desktop: desktop,
                            running: widget.running,
                            color: onCard,
                          ),
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
    );
  }
}
