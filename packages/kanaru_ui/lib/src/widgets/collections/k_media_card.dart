import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../theme/k_row_colors.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_space.dart';
import '../k_cover.dart';
import '../k_gap.dart';
import '../k_icon_button.dart';
import 'k_end_hit_extension.dart';
import 'k_media_card_frame.dart';
import 'k_media_card_right_column.dart';
import 'k_media_card_text.dart';

export 'k_media_card_text.dart' show KMediaCardMetrics;

/// Look of a [KMediaCard].
enum KMediaCardStyle {
  /// [flat] on the mobile shell, [card] on desktop.
  auto,

  /// Rounded tonal card; the list supplies the outer side space.
  card,

  /// Full-width row: no radius, the neutral fill (or the playing / selected
  /// colour), own 8 dp side padding (the same as a card).
  flat,
}

/// Row card of every media list: song, album track, queue, selection panel,
/// album, artist, folder, genre and language.
///
/// Slot order, left to right: [leading] (cover, with the selection mark) ·
/// text · [top] / [bottom] · [onAction] (play) · [accessory] (drag handle) ·
/// [trailing] (the ⋮).
/// The [trailing] button is always visible; only the play button appears on
/// hover or focus on desktop. Every button is a [KIconButton] that takes its
/// colours from the card (own ink on a tinted card). The end padding right of
/// the [trailing] button belongs to that button, and the few dp between the
/// right column, play button, accessory and ⋮ take a tap without acting, so a
/// near miss next to a button never plays the row.
///
/// Three text lines are always reserved (an empty line keeps its room) so all
/// cards of a list are the same height; [extentOf] gives that height without
/// laying anything out, in every [KMediaCardStyle]. Music-type-free: the
/// caller passes the cover as [leading] and every string.
/// With [loading] the lines show placeholder bars at the same height and a
/// null [leading] becomes a cover-sized placeholder block (round with
/// [circleLeading]).
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
    this.accessory,
    this.trailing,
    this.onAction,
    this.actionEnabled = true,
    this.actionIcon = KIcons.play,
    this.actionLabel,
    this.current = false,
    this.currentLabel,
    this.selected = false,
    this.selecting = false,
    this.dimmed = false,
    this.missing = false,
    this.editing = false,
    this.onTap,
    this.onLongPress,
    this.loading = false,
    this.style = KMediaCardStyle.auto,
    this.filled = true,
  }) : assert(
         onAction == null || actionLabel != null,
         'the play button needs a label for its tooltip and screen reader',
       );

  final String title;

  /// Small tag after the title (for example "auto-detected").
  final String? titleLabel;

  /// 1 (default) or 2. Two lines let a long name (a chain of folders) wrap;
  /// they take the room of the title and [line2], which is then not shown, so
  /// the card keeps its height.
  final int titleLines;
  final String? line2;
  final String? line3;

  /// The cover only (56 dp).
  final Widget? leading;

  /// The leading is round (artists): the selection check is clipped to match.
  final bool circleLeading;

  /// Right column, upper slot (duration).
  final Widget? top;

  /// Right column, lower slot: an icon button (a `KIconSize.sm` icon). The
  /// pair is laid out from its measured size, so a button with vertical
  /// padding and a bare icon both put the [top] text 2 dp above the icon; the
  /// text is drawn into the box's empty upper padding and ignores the pointer.
  final Widget? bottom;

  /// After the play button, before [trailing] (the drag handle of a reorderable
  /// row).
  final Widget? accessory;

  /// Last slot (the "more" button); always visible.
  final Widget? trailing;

  /// Plain play icon (no disc): always on the mobile shell, on hover or focus
  /// on desktop.
  final VoidCallback? onAction;

  /// False keeps the play button visible but disabled (nothing to play).
  final bool actionEnabled;
  final IconData actionIcon;
  final String? actionLabel;

  /// The row of the track that is playing: gradient from `primaryContainer`
  /// to `tertiaryContainer` (`KRowColors.playingGradient`).
  final bool current;

  /// Screen-reader text for [current] (for example "Now playing"), so the
  /// state is not conveyed by colour alone.
  final String? currentLabel;

  /// In the multi-select set: tinted `secondaryContainer`, check on the cover.
  final bool selected;

  /// A multi-select is active: unselected covers show the ring mark.
  final bool selecting;

  /// Unavailable item: dimmed, still tappable.
  final bool dimmed;

  /// The item's file is gone: dashed outline, dimmed, [line3] in the error
  /// colour. Still tappable; combines with [selected] and [current].
  final bool missing;

  /// The row of a list in edit mode: focusable by Tab and by click although it
  /// has no tap action (no tap callback runs); the focus ring shows while it
  /// has focus.
  final bool editing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Show placeholder bars in place of the text; [title] may be empty.
  final bool loading;

  /// See [KMediaCardStyle].
  final KMediaCardStyle style;

  /// Draws the neutral row fill (`KRowColors.fill`) in both styles. False for
  /// rows that sit on a surface of their own (the selection panel): flat
  /// transparent, or `surfaceContainerLow` as a card.
  final bool filled;

  /// Space below a card.
  static const double gap = KSpace.x1;

  /// Horizontal padding of a row, flat or card, at both ends. The end part
  /// belongs to the trailing button.
  static const double sidePadding = KSpace.x2;
  static const double coverSize = 56;
  static const double _padV = 10;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  /// Corner radius of a song or album cover inside a card.
  static const BorderRadius coverRadius = BorderRadius.all(Radius.circular(10));

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
  /// Set once the card is selected or a selection is active. Until then no
  /// cover overlay is mounted (most lists never select); afterwards it stays
  /// mounted so the off animation plays when the selection ends.
  bool _everActive = false;

  bool get _dim => widget.dimmed || widget.missing;

  @override
  Widget build(BuildContext context) {
    // Idempotent latch, derived from the widget: no setState needed.
    _everActive = _everActive || widget.selected || widget.selecting;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final flat =
        widget.style == KMediaCardStyle.flat ||
        (widget.style == KMediaCardStyle.auto && mobile);
    // The playing row (also when selected) draws a gradient over a
    // transparent material; every other state is one colour.
    final background = widget.current
        ? Colors.transparent
        : widget.selected
        ? scheme.secondaryContainer
        : widget.filled
        ? KRowColors.fill(Theme.of(context).brightness)
        : flat
        ? Colors.transparent
        : scheme.surfaceContainerLow;
    final ink = widget.current
        ? scheme.onPrimaryContainer
        : widget.selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final soft = widget.current || widget.selected
        ? ink.withValues(alpha: KRowColors.containerSoftAlpha)
        : scheme.onSurfaceVariant;

    // Height of the row content: the right column and the tap absorbers fill it.
    final rowHeight = widget.leading != null || widget.loading
        ? math.max(KMediaCard.coverSize, KMediaCardMetrics.textBlock(scaler))
        : KMediaCardMetrics.textBlock(scaler);
    // A loading card without a cover still draws a cover-sized block.
    final leading =
        widget.leading ??
        (widget.loading
            ? KCover.loading(
                size: KMediaCard.coverSize,
                radius: KMediaCard.coverRadius,
                circle: widget.circleLeading,
              )
            : null);

    final side = KMediaCard.sidePadding;
    Widget content(bool engaged) => Padding(
      // With a trailing button the end padding belongs to that button (see
      // KEndHitExtension), so a tap right of it is not a tap on the row.
      padding: EdgeInsetsDirectional.fromSTEB(
        side,
        KMediaCard._padV,
        widget.trailing != null ? 0 : side,
        KMediaCard._padV,
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
                // A dimmed card draws its mark outside the dim, below.
                if (_everActive && !(_dim && widget.selected))
                  Positioned.fill(
                    child: KMediaCardCoverCheck(
                      circle: widget.circleLeading,
                      selected: widget.selected,
                      selecting: widget.selecting,
                    ),
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
              line3Color: widget.missing ? scheme.error : null,
              ink: ink,
              soft: soft,
              loading: widget.loading,
              barColor: scheme.surfaceContainerHighest,
            ),
          ),
          if (widget.top != null || widget.bottom != null) ...[
            _TapAbsorber(width: KSpace.x2, height: rowHeight),
            // As high as the cover, so the button in [bottom] fits.
            KMediaCardRightColumn(
              height: rowHeight,
              topLine:
                  scaler.scale(textTheme.labelSmall?.fontSize ?? 11) * 1.45,
              top: widget.top == null
                  ? null
                  : IgnorePointer(
                      child: DefaultTextStyle.merge(
                        style: textTheme.labelSmall?.copyWith(color: soft),
                        child: widget.top!,
                      ),
                    ),
              bottom: widget.bottom,
            ),
          ],
          if (widget.onAction != null) ...[
            _TapAbsorber(width: KSpace.x2, height: rowHeight),
            KMediaCardRevealed(
              visible: mobile || engaged,
              child: KIconButton(
                tooltip: widget.actionLabel ?? '',
                size: KIconSize.sm,
                padding: const EdgeInsets.all(KSpace.x2),
                onPressed: widget.actionEnabled ? widget.onAction : null,
                icon: widget.actionIcon,
              ),
            ),
          ],
          if (widget.accessory != null) widget.accessory!,
          if (widget.trailing != null) ...[
            if (widget.accessory != null)
              _TapAbsorber(width: KSpace.x1, height: rowHeight),
            KEndHitExtension(extent: side, child: widget.trailing!),
          ],
        ],
      ),
    );

    // The check of a dimmed, selected card stays fully opaque: it is drawn
    // over the dimmed card, on the cover's spot.
    final markOutsideDim = _dim && widget.selected && leading != null;
    Widget card(Widget dimmedCard) => Stack(
      fit: StackFit.passthrough,
      children: [
        dimmedCard,
        // Always a Stack, the mark its last child, so the card keeps its
        // slot when the mark comes and goes.
        if (markOutsideDim)
          PositionedDirectional(
            start: KMediaCard.sidePadding,
            // The cover is centred in the row, which is as high as the
            // taller of the cover and the text block.
            top:
                KMediaCard._padV +
                (math.max(
                          KMediaCard.coverSize,
                          KMediaCardMetrics.textBlock(scaler),
                        ) -
                        KMediaCard.coverSize) /
                    2,
            width: KMediaCard.coverSize,
            height: KMediaCard.coverSize,
            child: IgnorePointer(
              child: KMediaCardCoverCheck(
                circle: widget.circleLeading,
                selected: true,
                selecting: true,
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: KMediaCard.gap),
      // A skeleton row carries no information: no semantics node at all.
      child: ExcludeSemantics(
        excluding: widget.loading,
        child: Semantics(
          selected: widget.selected,
          value: widget.current ? widget.currentLabel : null,
          child: card(
            KMediaCardFrame(
              background: background,
              gradient: widget.current
                  ? KRowColors.playingGradient(scheme)
                  : null,
              ink: ink,
              soft: soft,
              radius: flat ? BorderRadius.zero : KMediaCard._radius,
              dimmed: _dim,
              missing: widget.missing,
              focusable: widget.editing,
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              builder: (context, engaged) => content(engaged),
            ),
          ),
        ),
      ),
    );
  }
}

/// The gap between two row slots: takes a tap without doing anything, so a
/// near miss beside a button does not reach the row's own tap. Not announced.
class _TapAbsorber extends StatelessWidget {
  const _TapAbsorber({required this.width, required this.height});

  final double width;
  final double height;

  static void _ignore() {}

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _ignore,
      child: SizedBox(width: width, height: height),
    ),
  );
}
