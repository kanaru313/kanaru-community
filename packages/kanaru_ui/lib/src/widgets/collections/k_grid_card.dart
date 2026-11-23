import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/k_row_colors.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import 'k_media_card_frame.dart' show KMediaCardCoverCheck;

/// Tile of an album or artist grid: a square cover (or a round photo) as wide
/// as the tile, a title and a subtitle under it. Both texts take one line, so
/// every tile of a grid is [footerExtent] taller than it is wide (give that to
/// `KCollectionGrid.footerExtent`).
///
/// [filled] draws the album card: a faint `onSurface` fill with rounded
/// corners around the cover and the texts, the cover inset by [filledInset]
/// and rounded by [filledCoverRadius] (concentric with the card), the texts
/// indented and the title bolder. Tap and hover ink cover the whole card.
/// Only a filled card takes a third line ([detail]), the playing / selected
/// states and a [coverBadge] (song grid): those look like the song rows
/// (playing gradient, selected tint, the cover check of `KMediaCard`).
///
/// The cover is drawn by [coverBuilder] with the side it may use, so the
/// caller keeps the music types (cover files, seeds) and this widget the
/// layout.
class KGridCard extends StatelessWidget {
  const KGridCard({
    super.key,
    required this.coverBuilder,
    required this.title,
    this.subtitle,
    this.circle = false,
    this.filled = false,
    this.detail,
    this.current = false,
    this.currentLabel,
    this.selected = false,
    this.selecting = false,
    this.coverBadge,
    this.onTap,
    this.onLongPress,
    this.onMenu,
    this.menuLabel,
  }) : assert(onMenu == null || menuLabel != null, 'onMenu needs menuLabel'),
       assert(!(circle && filled), 'a round photo has no card'),
       assert(
         filled ||
             (detail == null &&
                 !current &&
                 !selected &&
                 !selecting &&
                 coverBadge == null),
         'only a filled card has a third line, states and a badge',
       );

  /// Draws the cover in a square of the given side.
  final Widget Function(BuildContext context, double side) coverBuilder;
  final String title;
  final String? subtitle;

  /// Round photo: the title and subtitle are centred.
  final bool circle;

  /// Album card: fill around the cover and texts (see the class doc).
  final bool filled;

  /// Third text line under [subtitle] (filled cards only; the song grid's
  /// `album • length`). Give the same to [footerExtent].
  final String? detail;

  /// The item is the one playing: the playing gradient and its ink.
  final bool current;

  /// Screen-reader text for [current] (for example "Now playing").
  final String? currentLabel;

  /// The item is in a multi-select: the selected tint and the cover check.
  final bool selected;

  /// A multi-select is active: unselected covers show the ring.
  final bool selecting;

  /// Small control at the cover's bottom-end corner, on a round backing the
  /// card draws (the song grid's heart). Null shows none.
  final Widget? coverBadge;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Opens the item's menu. The card has no ⋮ button: the caller wraps it in
  /// a context region (long press, right click); this gives screen readers
  /// the same menu as a custom action named [menuLabel].
  final VoidCallback? onMenu;

  /// Name of the screen-reader menu action (needed with [onMenu]).
  final String? menuLabel;

  /// Corner radius of the cover a [filled] card's caller draws: the card's
  /// radius less [filledInset], so both curves are concentric.
  static const BorderRadius filledCoverRadius = KRadius.xs;

  /// Space between a [filled] card's edge and its cover.
  static const double filledInset = KSpace.x1;

  static const double _titleSize = 14;
  static const double _subtitleSize = 12;
  static const double _lineHeight = 1.35;
  static const double _gap = KSpace.x2;

  // Filled card: titleSmall (14 / 20) and bodySmall (12 / 16) lines, the
  // texts indented 8 from the cover, 12 under the subtitle.
  static const double _filledTitleHeight = 20 / 14;
  static const double _filledSubtitleHeight = 16 / 12;
  static const double _filledTextInset = KSpace.x2;
  static const double _filledBottom = KSpace.x3;
  static const BorderRadius _filledRadius = KRadius.sm;
  static const double _badgeInset = 6;

  /// Height of the tile beyond its width for [scaler]: gap, title line,
  /// subtitle line; when [filled], also the card's padding (its cover is
  /// `2 * filledInset` narrower than the tile, so that part is subtracted).
  static double footerExtent(
    TextScaler scaler, {
    bool filled = false,
    bool detail = false,
  }) {
    if (!filled) {
      return _gap +
          scaler.scale(_titleSize) * _lineHeight +
          scaler.scale(_subtitleSize) * _lineHeight;
    }
    // Top inset + cover = tile width - filledInset; then gap, lines, bottom.
    return _gap +
        scaler.scale(_titleSize) * _filledTitleHeight +
        scaler.scale(_subtitleSize) * _filledSubtitleHeight * (detail ? 2 : 1) +
        _filledBottom -
        filledInset;
  }

  @override
  Widget build(BuildContext context) {
    final menuLabel = this.menuLabel;
    return Semantics(
      button: onTap != null,
      selected: filled && (selected || selecting) ? selected : null,
      value: current ? currentLabel : null,
      customSemanticsActions: onMenu == null || menuLabel == null
          ? null
          : {CustomSemanticsAction(label: menuLabel): onMenu!},
      child: filled ? _filledCard(context) : _plainCard(context),
    );
  }

  Widget _plainCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final align = circle ? TextAlign.center : TextAlign.start;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: KRadius.md,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth;
          return Column(
            crossAxisAlignment: circle
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: side,
                child: coverBuilder(context, side),
              ),
              const SizedBox(height: _gap),
              _line(
                title,
                align,
                textTheme.bodyMedium?.copyWith(
                  fontSize: _titleSize,
                  height: _lineHeight,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              _line(
                subtitle ?? '',
                align,
                textTheme.bodySmall?.copyWith(
                  fontSize: _subtitleSize,
                  height: _lineHeight,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filledCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const shape = RoundedRectangleBorder(borderRadius: _filledRadius);
    // Same colours as a song row in the same state.
    final ink = current
        ? scheme.onPrimaryContainer
        : selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final soft = current || selected
        ? ink.withValues(alpha: KRowColors.containerSoftAlpha)
        : scheme.onSurfaceVariant;
    final detail = this.detail;
    final badge = coverBadge;
    final card = Material(
      color: current
          ? Colors.transparent
          : selected
          ? scheme.secondaryContainer
          : scheme.onSurface.withValues(alpha: 0.06),
      shape: shape,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            filledInset,
            filledInset,
            filledInset,
            _filledBottom,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: side,
                    child: Stack(
                      children: [
                        Positioned.fill(child: coverBuilder(context, side)),
                        if (selected || selecting)
                          Positioned.fill(
                            child: KMediaCardCoverCheck(
                              circle: false,
                              selected: selected,
                              selecting: selecting,
                              radius: filledCoverRadius,
                            ),
                          ),
                        if (badge != null)
                          PositionedDirectional(
                            end: _badgeInset,
                            bottom: _badgeInset,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.surface.withValues(alpha: 0.78),
                              ),
                              child: badge,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _gap),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _filledTextInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line(
                          title,
                          TextAlign.start,
                          textTheme.titleSmall?.copyWith(
                            fontSize: _titleSize,
                            height: _filledTitleHeight,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        for (final line in [subtitle ?? '', ?detail])
                          _line(
                            line,
                            TextAlign.start,
                            textTheme.bodySmall?.copyWith(
                              fontSize: _subtitleSize,
                              height: _filledSubtitleHeight,
                              color: soft,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (!current) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: KRowColors.playingGradient(scheme),
        borderRadius: _filledRadius,
      ),
      child: card,
    );
  }

  /// One text line, exactly `fontSize * height` tall: a fallback font (CJK
  /// titles on Android) has taller metrics than the theme font and would
  /// make the line, and so the card, taller than [footerExtent].
  static Widget _line(String text, TextAlign align, TextStyle? style) =>
      SizedBox(
        width: double.infinity,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: style,
          strutStyle: style == null
              ? null
              : StrutStyle.fromTextStyle(style, forceStrutHeight: true),
        ),
      );
}
