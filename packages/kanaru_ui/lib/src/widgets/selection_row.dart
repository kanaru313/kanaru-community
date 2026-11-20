import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_check_mark.dart';
import 'collections/k_media_card.dart';
import 'k_gap.dart';
import 'k_inset_shape.dart';
import 'k_row_edges.dart';
import 'selection_action_row.dart';

/// One option of a choice list, tonal rounded fill and bold title when
/// selected. No radio buttons.
///
/// Text row ([leading] null): a [KCheckMark] (ring / disc + tick) at the start,
/// single and multi choice alike. Icon row: the icon, no mark for a single
/// choice; with [multi] a [KCheckMarkStyle.plain] tick in a 24 slot on the
/// right (empty when unchosen, so titles keep their width). A single-choice
/// icon row of [alikeOptions] (pictures that look alike) gets that same plain
/// tick, because tint alone does not show the choice. The tint's edges follow
/// the host's [KRowEdges]: square and full width in a bottom sheet, rounded
/// and inset [KSpace.x2] elsewhere (see [KRowEdgesScope]). [multi] rows expose
/// checkbox semantics, others radio-group semantics.
class SelectionRow extends StatelessWidget {
  const SelectionRow({
    super.key,
    required this.title,
    required this.selected,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.multi = false,
    this.partial = false,
    this.plainMark = false,
    this.alikeOptions = false,
    this.dense = false,
    this.autofocus = false,
    this.hint,
    this.onTap,
  }) : action = false,
       disabledReason = null,
       opensMore = false,
       running = false,
       mediaTitle = null,
       mediaLine2 = null,
       mediaTag = null,
       circleCover = false;

  /// A start button, not a choice: it does its thing when tapped. No check
  /// mark, no selected / checked semantics (it has no `selected`, `multi`,
  /// `partial`, `plainMark` or `alikeOptions`). [subtitle] is its detail
  /// ("còn 2:48"): under the title on touch shells, on the same line to the
  /// right on desktop (the dense 40 / 36 geometry, chosen here from the
  /// shell). [disabledReason] and [opensMore] are described on their fields;
  /// [running] makes it the card that leads back to what is already running.
  /// Keyboard focus draws the 2 dp `primary` ring around the visible shape.
  const SelectionRow.action({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.autofocus = false,
    this.hint,
    this.onTap,
    this.disabledReason,
    this.opensMore = false,
    this.running = false,
  }) : action = true,
       selected = false,
       multi = false,
       partial = false,
       plainMark = false,
       alikeOptions = false,
       dense = false,
       mediaTitle = null,
       mediaLine2 = null,
       mediaTag = null,
       circleCover = false;

  /// A row with a cover (song, album, artist, playlist, image): the library's
  /// [KMediaCard] row (size, cover, text styles, padding, gap below) with the
  /// selection on top, so a change to library rows changes pickers too. Single
  /// choice of [alikeOptions] covers and [multi] rows get the plain tick on
  /// the right, like icon rows. [cover] is the 56 dp cover widget.
  const SelectionRow.media({
    super.key,
    required String this.mediaTitle,
    required Widget cover,
    required this.selected,
    this.mediaLine2,
    this.mediaTag,
    this.circleCover = false,
    this.enabled = true,
    this.multi = false,
    this.partial = false,
    this.alikeOptions = false,
    this.autofocus = false,
    this.hint,
    this.onTap,
  }) : title = const SizedBox.shrink(),
       subtitle = null,
       leading = cover,
       plainMark = false,
       dense = false,
       action = false,
       disabledReason = null,
       opensMore = false,
       running = false;

  /// Set only by [SelectionRow.media]: the card's title, second line and tag.
  final String? mediaTitle;
  final String? mediaLine2;
  final String? mediaTag;

  /// The cover is round (artists).
  final bool circleCover;

  final Widget title;
  final Widget? subtitle;

  /// Icon or logo; omit it and the text starts at the edge.
  final Widget? leading;
  final bool selected;

  /// A disabled row is dimmed and ignores taps.
  final bool enabled;

  /// One of several choices (checkbox semantics) instead of one of a group.
  final bool multi;

  /// Dash instead of tick: some, not all, of what this row stands for is
  /// chosen. Only meaningful with [multi].
  final bool partial;

  /// Icon-row layout without an icon of its own (the select-all row of an
  /// icon list): plain tick on the right, nothing at the start.
  final bool plainMark;

  /// The options look alike (pictures), so tint alone is not enough to show
  /// the single choice: an icon row shows the plain tick on the right of the
  /// chosen row (empty slot on the others). No effect on text rows or [multi].
  final bool alikeOptions;

  /// Compact row of menus and dropdowns: `bodyMedium` text, 12 dp gaps, 12 dp
  /// side padding. 40 dp hit area on both shells, the visible shape (tint,
  /// hover, press, focus) is 36 dp, centred, with a transparent band above and
  /// below that still takes taps. Pass the icon at `KIconSize.sm`.
  final bool dense;

  /// Takes keyboard focus when its route opens (the chosen row of a menu).
  final bool autofocus;

  /// What choosing this row does or means: the row's accessible description
  /// (no visible text; the ⓘ explanation widget reads it later).
  final String? hint;
  final VoidCallback? onTap;

  /// A start button, not a choice: it does its thing when tapped. No check
  /// mark, no selected / checked semantics (pass `selected: false`), the
  /// [subtitle] is its detail ("còn 2:48"): under the title on touch shells,
  /// on the same line to the right on desktop (the dense 40 / 36 geometry,
  /// chosen here from the shell).
  final bool action;

  /// Why an action row cannot be used: the row is dimmed, skipped by arrow
  /// keys and Tab, and this text replaces its detail.
  final String? disabledReason;

  /// An action row that opens a further screen ("Sau số bài…"): outlined on
  /// touch shells, `primary` bold title on desktop.
  final bool opensMore;

  /// A tonal `primaryContainer` card with a trailing `›`: the way back to
  /// what is already running.
  final bool running;

  static const double _checkSlot = 24;

  Widget _buildMedia(BuildContext context, KRowEdges? edges) {
    final mixed = multi && partial;
    final showTick = multi || alikeOptions;
    return Semantics(
      enabled: enabled,
      hint: hint,
      inMutuallyExclusiveGroup: multi ? null : true,
      checked: multi && !mixed ? selected : null,
      mixed: mixed ? true : null,
      child: Padding(
        // A card's list supplies the outer side space; a flat row has none.
        padding: EdgeInsets.symmetric(horizontal: edges.sideGap),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: KMediaCard(
            title: mediaTitle!,
            titleLabel: mediaTag,
            line2: mediaLine2,
            leading: leading,
            circleLeading: circleCover,
            selected: selected,
            coverMark: false,
            announceSelected: !multi,
            filled: false,
            style: switch (edges) {
              KRowEdges.fullBleed => KMediaCardStyle.flat,
              KRowEdges.inset => KMediaCardStyle.card,
              null => KMediaCardStyle.auto,
            },
            trailing: showTick
                ? Padding(
                    padding: const EdgeInsets.only(right: KSpace.x2),
                    child: KCheckMark(
                      size: _checkSlot,
                      state: mixed
                          ? KCheckState.partial
                          : selected
                          ? KCheckState.on
                          : KCheckState.off,
                      style: KCheckMarkStyle.plain,
                    ),
                  )
                : null,
            onTap: enabled ? onTap : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final minHeight = dense
        ? KLayout.dropdownRowHeight
        : (mobile ? KLayout.minTarget + KSpace.x2 : KLayout.minTarget);
    // Transparent band above and below the visible shape of a dense row.
    final band = dense
        ? (KLayout.dropdownRowHeight - KLayout.dropdownRowVisible) / 2
        : 0.0;
    final gap = dense ? KSpace.x3 : KSpace.x4;
    final bodyStyle = dense ? textTheme.bodyMedium : textTheme.bodyLarge;
    final active = enabled && onTap != null;
    if (action) {
      return SelectionActionRow(
        title: title,
        subtitle: subtitle,
        leading: leading,
        disabledReason: disabledReason,
        enabled: enabled,
        opensMore: opensMore,
        running: running,
        autofocus: autofocus,
        hint: hint,
        onTap: onTap,
      );
    }
    final edges = KRowEdgesScope.maybeOf(context);
    if (mediaTitle != null) return _buildMedia(context, edges);
    final corners = edges.corners(KRadius.md);
    final iconLayout = leading != null || plainMark;
    final mixed = multi && partial;
    final state = mixed
        ? KCheckState.partial
        : selected
        ? KCheckState.on
        : KCheckState.off;
    return Semantics(
      enabled: enabled,
      hint: hint,
      selected: multi ? null : selected,
      inMutuallyExclusiveGroup: multi ? null : true,
      // Flutter asserts checked is unset while mixed.
      checked: multi && !mixed ? selected : null,
      mixed: mixed ? true : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: edges.sideGap),
          child: Stack(
            children: [
              // Tint on the visible shape only; ink and focus use the same
              // inset shape, taps use the whole row.
              Positioned.fill(
                top: band,
                bottom: band,
                child: AnimatedContainer(
                  duration: KMotion.fast,
                  decoration: ShapeDecoration(
                    shape: KShape.of(corners),
                    color: selected
                        ? scheme.secondaryContainer
                        // Same hue at alpha 0: lerping to black (0x00000000)
                        // would pass through a grey on the way out.
                        : scheme.secondaryContainer.withValues(alpha: 0),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: KInsetShape(KShape.of(corners), band),
                  // M3 state layers (8 % hover, 10 % press/focus of onSurface),
                  // as the mockups draw them; the theme default (4 %) is too
                  // faint to see on surfaceContainerHighest menus.
                  hoverColor: scheme.onSurface.withValues(alpha: 0.08),
                  focusColor: scheme.onSurface.withValues(alpha: 0.10),
                  highlightColor: scheme.onSurface.withValues(alpha: 0.10),
                  autofocus: autofocus,
                  onTap: active ? onTap : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            (dense ? KSpace.x3 : KSpace.x4) +
                            edges.contentExtra,
                        vertical: KSpace.x2,
                      ),
                      child: Row(
                        children: [
                          if (!iconLayout) ...[
                            KCheckMark(size: _checkSlot, state: state),
                            const KGap(KSpace.x3),
                          ] else if (leading != null) ...[
                            IconTheme.merge(
                              data: IconThemeData(
                                color: scheme.onSurfaceVariant,
                              ),
                              child: leading!,
                            ),
                            KGap(gap),
                          ],
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DefaultTextStyle.merge(
                                  style: bodyStyle?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : null,
                                  ),
                                  child: title,
                                ),
                                if (subtitle != null)
                                  DefaultTextStyle.merge(
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    child: subtitle!,
                                  ),
                              ],
                            ),
                          ),
                          if (iconLayout &&
                              (multi || (alikeOptions && leading != null))) ...[
                            const KGap(KSpace.x3),
                            KCheckMark(
                              size: _checkSlot,
                              state: state,
                              style: KCheckMarkStyle.plain,
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
