import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../theme/k_row_colors.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_space.dart';
import '../k_cover.dart';
import '../k_gap.dart';
import 'k_media_card_frame.dart';
import 'k_media_card_right_column.dart';
import 'k_media_card_text.dart';

/// Look of a [KMediaCard].
enum KMediaCardStyle {
  /// [flat] on the mobile shell, [card] on desktop.
  auto,

  /// Rounded tonal card; the list supplies the outer side space.
  card,

  /// Full-width row: no radius, the neutral fill (or the playing / selected
  /// colour), own
  /// 16 dp side padding so content lines up with page headers.
  flat,
}

/// Row card of every media list: song, album track, queue, selection panel,
/// album, artist, folder, genre and language.
///
/// Slot order, left to right: [leading] (cover, with the selection mark) ·
/// text · [top] / [bottom] · [onAction] (play) · [accessory] (drag handle) ·
/// [trailing] (the ⋮).
/// The [trailing] button is always visible; only the play button appears on
/// hover or focus on desktop.
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
    this.dimmed = false,
    this.onTap,
    this.onLongPress,
    this.loading = false,
    this.style = KMediaCardStyle.auto,
    this.filled = true,
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

  /// The cover only (56 dp).
  final Widget? leading;

  /// The leading is round (artists): the selection check is clipped to match.
  final bool circleLeading;

  /// Right column, upper slot (duration).
  final Widget? top;

  /// Right column, lower slot: an icon button (about a 20 dp icon). The pair is
  /// laid out from its measured size, so a 48 dp mobile box, a 40 dp desktop
  /// box and a bare icon all put the [top] text 2 dp above the icon; the text
  /// is drawn into the box's empty upper padding and ignores the pointer.
  final Widget? bottom;

  /// After the play button, before [trailing] (the drag handle of a reorderable
  /// row).
  final Widget? accessory;

  /// Last slot (the "more" button); always visible.
  final Widget? trailing;

  /// Round tonal play button: always on the mobile shell, on hover or focus
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

  /// Unavailable item: dimmed, still tappable.
  final bool dimmed;
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
  @override
  Widget build(BuildContext context) {
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

    Widget content(bool engaged) => Padding(
      padding: EdgeInsets.symmetric(
        horizontal: flat ? KLayout.gutterMobile : KSpace.x3,
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
                // A dimmed card draws its mark outside the dim, below.
                if (widget.selected && !widget.dimmed)
                  Positioned.fill(
                    child: KMediaCardSelectedMark(circle: widget.circleLeading),
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
            KMediaCardRightColumn(
              height: leading != null
                  ? math.max(
                      KMediaCard.coverSize,
                      KMediaCardMetrics.textBlock(scaler),
                    )
                  : KMediaCardMetrics.textBlock(scaler),
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
            const KGap(KSpace.x2),
            KMediaCardRevealed(
              visible: mobile || engaged,
              child: IconButton.filledTonal(
                tooltip: widget.actionLabel,
                onPressed: widget.actionEnabled ? widget.onAction : null,
                icon: Icon(widget.actionIcon),
              ),
            ),
          ],
          // The right column and play button butt against the next 48 dp
          // box; handle to ⋮ keeps its 4 dp.
          if (widget.accessory != null) widget.accessory!,
          if (widget.trailing != null) ...[
            if (widget.accessory != null) const KGap(KSpace.x1),
            widget.trailing!,
          ],
        ],
      ),
    );

    // The check of a dimmed, selected card stays fully opaque: it is drawn
    // over the dimmed card, on the cover's spot.
    final markOutsideDim = widget.dimmed && widget.selected && leading != null;
    Widget card(Widget dimmedCard) => Stack(
      fit: StackFit.passthrough,
      children: [
        dimmedCard,
        // Always a Stack, the mark its last child, so the card keeps its
        // slot when the mark comes and goes.
        if (markOutsideDim)
          PositionedDirectional(
            start: flat ? KLayout.gutterMobile : KSpace.x3,
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
              child: KMediaCardSelectedMark(circle: widget.circleLeading),
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
              dimmed: widget.dimmed,
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
