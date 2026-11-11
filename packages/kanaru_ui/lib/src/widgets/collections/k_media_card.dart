import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// Row card of every media list: song, album, artist, folder.
///
/// Three text lines are always reserved (an empty line keeps its room) so all
/// cards of a list are the same height; [extentOf] gives that height without
/// laying anything out. Music-type-free: the caller passes the cover (or a
/// number column) as [leading] and every string.
class KMediaCard extends StatefulWidget {
  const KMediaCard({
    super.key,
    required this.title,
    this.titleLabel,
    this.titleLines = 1,
    this.line2,
    this.line3,
    this.leading,
    this.circleLeading = false,
    this.top,
    this.bottom,
    this.trailing,
    this.onAction,
    this.actionIcon = KIcons.play,
    this.actionLabel,
    this.revealTrailingOnHover = false,
    this.current = false,
    this.currentLabel,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;

  /// Small tag after the title (for example "auto-detected").
  final String? titleLabel;

  /// 1 (default) or 2. Two lines let a long name (a chain of folders) wrap;
  /// they take the room of the title and [line2], which is then not shown, so
  /// the card keeps its height.
  final int titleLines;
  final String? line2;
  final String? line3;

  /// Cover (56 dp) or number column.
  final Widget? leading;

  /// The leading is round (artists): the selection check is clipped to match.
  final bool circleLeading;

  /// Right column, upper slot (duration).
  final Widget? top;

  /// Right column, lower slot (favourite button, up to 48 dp tall; it overlaps the upper slot's row, which holds a short label).
  final Widget? bottom;

  /// Last slot (the "more" button).
  final Widget? trailing;

  /// Round tonal play button: always on the mobile shell, on hover or focus
  /// on desktop.
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String? actionLabel;

  /// Desktop: show [trailing] only on hover, focus or while [selected].
  final bool revealTrailingOnHover;

  /// The row of the track that is playing: tinted `primaryContainer`.
  final bool current;

  /// Screen-reader text for [current] (for example "Now playing"), so the
  /// state is not conveyed by colour alone.
  final String? currentLabel;

  /// In the multi-select set: tinted `secondaryContainer`, check on the cover.
  final bool selected;

  /// Unavailable item: dimmed, still tappable.
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Space below a card.
  static const double gap = KSpace.x1;
  static const double coverSize = 56;
  static const double _padV = 10;
  static const double _titleSize = 15;
  static const double _lineSize = 13;
  static const double _lineHeight = 1.35;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  static double _line(TextScaler s, double size) => s.scale(size) * _lineHeight;

  static double _textBlock(TextScaler s) =>
      _line(s, _titleSize) + 2 * _line(s, _lineSize);

  /// Laid-out height of a card plus [gap], for a fixed list extent.
  /// Assumes a 56 dp leading (cover or number column); pass
  /// `hasLeading: false` for cards without one.
  static double extentOf(TextScaler scaler, {bool hasLeading = true}) =>
      (hasLeading && coverSize > _textBlock(scaler)
          ? coverSize
          : _textBlock(scaler)) +
      2 * _padV +
      gap;

  @override
  State<KMediaCard> createState() => _KMediaCardState();
}

class _KMediaCardState extends State<KMediaCard> {
  bool _hovered = false;
  bool _focused = false;

  bool get _engaged => _hovered || _focused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final background = widget.current
        ? scheme.primaryContainer
        : widget.selected
        ? scheme.secondaryContainer
        : scheme.surfaceContainerLow;
    final ink = widget.current
        ? scheme.onPrimaryContainer
        : widget.selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final soft = widget.current || widget.selected
        ? ink.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant;

    Widget line(String? text, double size, TextStyle? base, Color color) {
      return SizedBox(
        height: KMediaCard._line(scaler, size),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: Text(
            text ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base?.copyWith(
              fontSize: size,
              height: KMediaCard._lineHeight,
              color: color,
            ),
          ),
        ),
      );
    }

    final titleStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final reveal = mobile || _engaged || widget.selected;
    final leading = widget.leading;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpace.x3,
        vertical: KMediaCard._padV,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            Stack(
              children: [
                SizedBox(
                  width: KMediaCard.coverSize,
                  height: KMediaCard.coverSize,
                  child: Center(child: leading),
                ),
                if (widget.selected)
                  Positioned.fill(
                    child: _SelectedMark(circle: widget.circleLeading),
                  ),
              ],
            ),
            const KGap(KSpace.x3),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: widget.titleLines == 2
                          ? SizedBox(
                              height:
                                  KMediaCard._line(
                                    scaler,
                                    KMediaCard._titleSize,
                                  ) +
                                  KMediaCard._line(
                                    scaler,
                                    KMediaCard._lineSize,
                                  ),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  widget.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle?.copyWith(
                                    fontSize: KMediaCard._titleSize,
                                    color: ink,
                                    // Two lines in the room of a title and a
                                    // second line.
                                    height:
                                        (KMediaCard._line(
                                              scaler,
                                              KMediaCard._titleSize,
                                            ) +
                                            KMediaCard._line(
                                              scaler,
                                              KMediaCard._lineSize,
                                            )) /
                                        (2 *
                                            scaler.scale(
                                              KMediaCard._titleSize,
                                            )),
                                  ),
                                ),
                              ),
                            )
                          : line(
                              widget.title,
                              KMediaCard._titleSize,
                              titleStyle,
                              ink,
                            ),
                    ),
                    if (widget.titleLabel != null) ...[
                      const KGap(KSpace.x2),
                      Text(
                        widget.titleLabel!,
                        maxLines: 1,
                        style: textTheme.labelSmall?.copyWith(color: soft),
                      ),
                    ],
                  ],
                ),
                if (widget.titleLines != 2)
                  line(
                    widget.line2,
                    KMediaCard._lineSize,
                    textTheme.bodySmall,
                    soft,
                  ),
                line(
                  widget.line3,
                  KMediaCard._lineSize,
                  textTheme.bodySmall,
                  soft,
                ),
              ],
            ),
          ),
          if (widget.top != null || widget.bottom != null) ...[
            const KGap(KSpace.x2),
            // As high as the cover, so a 48 dp button in [bottom] fits.
            SizedBox(
              height: leading != null
                  ? math.max(
                      KMediaCard.coverSize,
                      KMediaCard._textBlock(scaler),
                    )
                  : KMediaCard._textBlock(scaler),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: DefaultTextStyle.merge(
                      style: textTheme.labelSmall?.copyWith(color: soft),
                      child: widget.top ?? const SizedBox.shrink(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: widget.bottom ?? const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
          if (widget.onAction != null) ...[
            const KGap(KSpace.x2),
            _Revealed(
              visible: mobile || _engaged,
              child: IconButton.filledTonal(
                tooltip: widget.actionLabel,
                onPressed: widget.onAction,
                icon: Icon(widget.actionIcon),
              ),
            ),
          ],
          if (widget.trailing != null) ...[
            const KGap(KSpace.x1),
            widget.revealTrailingOnHover
                ? _Revealed(visible: reveal, child: widget.trailing!)
                : widget.trailing!,
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: KMediaCard.gap),
      child: Semantics(
        selected: widget.selected,
        value: widget.current ? widget.currentLabel : null,
        child: Opacity(
          opacity: widget.dimmed ? 0.5 : 1,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (v) => setState(() => _focused = v),
              child: Material(
                color: background,
                shape: const RoundedRectangleBorder(
                  borderRadius: KMediaCard._radius,
                ),
                clipBehavior: Clip.antiAlias,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: ink),
                  child: IconTheme.merge(
                    data: IconThemeData(color: soft),
                    child: InkWell(
                      onTap: widget.onTap,
                      onLongPress: widget.onLongPress,
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps its room when hidden so the card does not shift; hidden children
/// stay focusable (Tab reveals them) but ignore the pointer.
class _Revealed extends StatelessWidget {
  const _Revealed({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: KMotion.fast,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}

/// Primary tint with a white check over a cover.
class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.circle});

  final bool circle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.55),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : KRadius.sm,
      ),
      child: Icon(KIcons.check, color: scheme.onPrimary),
    );
  }
}
