import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import 'k_media_card_text.dart';

/// Look of a [KMediaCard].
enum KMediaCardStyle {
  /// [flat] on the mobile shell, [card] on desktop.
  auto,

  /// Rounded tonal card; the list supplies the outer side space.
  card,

  /// Full-width row: no radius, no fill unless current or selected, own
  /// 16 dp side padding so content lines up with page headers.
  flat,
}

/// Row card of every media list: song, album, artist, folder.
///
/// Slot order, left to right: [prefix] (track number or desktop drag handle) ·
/// [leading] (cover, with the selection mark) · text · [top] / [bottom] ·
/// [onAction] (play) · [accessory] (mobile drag handle) · [trailing] (the ⋮).
/// The [trailing] button is always visible; only the play button appears on
/// hover or focus on desktop.
///
/// Three text lines are always reserved (an empty line keeps its room) so all
/// cards of a list are the same height; [extentOf] gives that height without
/// laying anything out, in every [KMediaCardStyle]. Music-type-free: the
/// caller passes the cover as [leading] and every string.
/// With [loading] the lines show placeholder bars at the same height.
class KMediaCard extends StatefulWidget {
  const KMediaCard({
    super.key,
    required this.title,
    this.titleLabel,
    this.titleLines = 1,
    this.line2,
    this.line3,
    this.prefix,
    this.leading,
    this.circleLeading = false,
    this.top,
    this.bottom,
    this.accessory,
    this.trailing,
    this.onAction,
    this.actionIcon = KIcons.play,
    this.actionLabel,
    this.current = false,
    this.currentLabel,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
    this.onLongPress,
    this.loading = false,
    this.style = KMediaCardStyle.auto,
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

  /// Before the [leading], in a [prefixWidth] box, centred and scaled down to
  /// fit (a track number, a desktop drag handle). Null takes no room.
  final Widget? prefix;

  /// The cover only (56 dp).
  final Widget? leading;

  /// The leading is round (artists): the selection check is clipped to match.
  final bool circleLeading;

  /// Right column, upper slot (duration).
  final Widget? top;

  /// Right column, lower slot (favourite button, up to 48 dp tall; it overlaps the upper slot's row, which holds a short label).
  final Widget? bottom;

  /// After the play button, before [trailing] (for example the mobile drag
  /// handle).
  final Widget? accessory;

  /// Last slot (the "more" button); always visible.
  final Widget? trailing;

  /// Round tonal play button: always on the mobile shell, on hover or focus
  /// on desktop.
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String? actionLabel;

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

  /// Show placeholder bars in place of the text; [title] may be empty.
  final bool loading;

  /// See [KMediaCardStyle].
  final KMediaCardStyle style;

  /// Space below a card.
  static const double gap = KSpace.x1;
  static const double coverSize = 56;
  static const double prefixWidth = 40;
  static const double _padV = 10;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  /// Laid-out height of a card plus [gap], for a fixed list extent.
  /// Assumes a 56 dp leading (the cover); pass
  /// `hasLeading: false` for cards without one.
  static double extentOf(TextScaler scaler, {bool hasLeading = true}) =>
      (hasLeading && coverSize > KMediaCardMetrics.textBlock(scaler)
          ? coverSize
          : KMediaCardMetrics.textBlock(scaler)) +
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
    final flat =
        widget.style == KMediaCardStyle.flat ||
        (widget.style == KMediaCardStyle.auto && mobile);
    final tinted = widget.current || widget.selected;
    final background = widget.current
        ? scheme.primaryContainer
        : widget.selected
        ? scheme.secondaryContainer
        : flat
        ? Colors.transparent
        : scheme.surfaceContainerLow;
    final ink = widget.current
        ? scheme.onPrimaryContainer
        : widget.selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final soft = widget.current || widget.selected
        ? ink.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant;

    // Inherited icon-button theme, restored for the play button and merged
    // into the tinted style so a caller's density or size still applies.
    final ambientButtons = IconButtonTheme.of(context);
    final prefix = widget.prefix;
    final leading = widget.leading;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: flat ? KLayout.gutterMobile : KSpace.x3,
        vertical: KMediaCard._padV,
      ),
      child: Row(
        children: [
          if (prefix != null) ...[
            SizedBox(
              width: KMediaCard.prefixWidth,
              // Bounded height, or the Center would fill the card's max.
              height: KMediaCard.coverSize,
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: prefix),
              ),
            ),
            const KGap(KSpace.x2),
          ],
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
            child: KMediaCardText(
              title: widget.title,
              titleLabel: widget.titleLabel,
              titleLines: widget.titleLines,
              line2: widget.line2,
              line3: widget.line3,
              ink: ink,
              soft: soft,
              loading: widget.loading,
              barColor: scheme.surfaceContainerHighest,
            ),
          ),
          if (widget.top != null || widget.bottom != null) ...[
            const KGap(KSpace.x2),
            // As high as the cover, so a 48 dp button in [bottom] fits.
            SizedBox(
              height: leading != null
                  ? math.max(
                      KMediaCard.coverSize,
                      KMediaCardMetrics.textBlock(scaler),
                    )
                  : KMediaCardMetrics.textBlock(scaler),
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
              // Keeps its own colours inside a tinted card.
              child: _withButtons(
                tinted,
                ambientButtons,
                IconButton.filledTonal(
                  tooltip: widget.actionLabel,
                  onPressed: widget.onAction,
                  icon: Icon(widget.actionIcon),
                ),
              ),
            ),
          ],
          if (widget.accessory != null) ...[
            const KGap(KSpace.x1),
            widget.accessory!,
          ],
          if (widget.trailing != null) ...[
            const KGap(KSpace.x1),
            widget.trailing!,
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
                shape: RoundedRectangleBorder(
                  borderRadius: flat ? BorderRadius.zero : KMediaCard._radius,
                ),
                clipBehavior: Clip.antiAlias,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: ink),
                  child: IconTheme.merge(
                    data: IconThemeData(color: soft),
                    // M3 IconButton ignores IconTheme: colour it here so icons
                    // contrast with the tint.
                    child: _withButtons(
                      tinted,
                      IconButtonThemeData(
                        // ButtonStyle.merge keeps the receiver's values: the card
                        // colour wins over an inherited foreground and the other
                        // inherited properties stay.
                        style: IconButton.styleFrom(foregroundColor: soft)
                            .copyWith(iconColor: WidgetStatePropertyAll(soft))
                            .merge(ambientButtons.style),
                      ),
                      InkWell(
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
      ),
    );
  }
}

/// Wraps [child] in [data] only when [apply]; otherwise the inherited
/// `IconButtonTheme` stays untouched.
Widget _withButtons(bool apply, IconButtonThemeData data, Widget child) =>
    apply ? IconButtonTheme(data: data, child: child) : child;

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
