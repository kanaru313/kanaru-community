import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_font.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';

/// Meaning of a [KChip.tag]: [neutral] is the default (`secondaryContainer`);
/// [highlight] marks a good or special state (`tertiaryContainer`, "Đồng
/// bộ"); [muted] a plain value (`surfaceContainerHighest`, "Thường");
/// [problem] a warning (`errorContainer`, "Nguồn đang tắt"). Ignored with
/// `outlined`.
enum KTagTone { neutral, highlight, muted, problem }

/// Tonal pill. 48 dp tall on touch shells, 40 on desktop; [dense] makes it
/// 40 r12 on touch shells and 32 on desktop (a chip row that must fit).
class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.dense = false,
    this.semanticLabel,
    this.onRaised = false,
    this.tintWhenSelected = true,
    this.outlined = false,
  }) : trailing = null,
       tone = KTagTone.neutral,
       _interactive = true,
       _tag = false,
       _token = false;

  /// A pill that is a value, not a choice: no button, no selected state, no
  /// ink. [trailing] (a remove button) sits at the end with less padding.
  /// Use it for chips that only show something, or hold their own action.
  const KChip.static({super.key, required this.label, this.trailing})
    : icon = null,
      selected = false,
      enabled = true,
      onTap = null,
      dense = false,
      semanticLabel = null,
      onRaised = false,
      outlined = false,
      tintWhenSelected = true,
      tone = KTagTone.neutral,
      _interactive = false,
      _tag = false,
      _token = false;

  /// A small label that only shows a value (the kind and the author on a
  /// plugin row): 20 dp tall, `labelSmall`, radius 6, label centred, no ink,
  /// never a button. Filled with `secondaryContainer`, or only outlined when
  /// [outlined]; one line, a long label ends with an ellipsis. An optional
  /// [icon] sits before the label. `enabled: false` marks a value that does
  /// not apply: outlined and dimmed (the caller says it in words for screen
  /// readers). Put it in a [KTagRow]. At 1.5x text it grows with the label.
  const KChip.tag({
    super.key,
    required this.label,
    this.outlined = false,
    this.tone = KTagTone.neutral,
    this.icon,
    this.enabled = true,
  }) : selected = false,
       onTap = null,
       dense = true,
       semanticLabel = null,
       onRaised = false,
       trailing = null,
       tintWhenSelected = true,
       _interactive = false,
       _tag = true,
       _token = false;

  /// A small insertable code token (a prompt variable such as `{title}`):
  /// outlined (1 dp `outlineVariant`, no fill), radius 8, 28 dp visible
  /// height, 10 dp side padding, label in the mono font at 12 sp. The tap area
  /// is the visible chip itself (28 dp), the same on both shells, never padded
  /// to 48 dp.
  const KChip.token({
    super.key,
    required this.label,
    this.enabled = true,
    this.onTap,
    this.semanticLabel,
  }) : icon = null,
       selected = false,
       dense = true,
       onRaised = false,
       trailing = null,
       outlined = true,
       tintWhenSelected = true,
       tone = KTagTone.neutral,
       _interactive = true,
       _tag = false,
       _token = true;

  final Widget label;
  final Widget? icon;
  final bool selected;

  /// A disabled chip is dimmed and ignores taps.
  final bool enabled;
  final VoidCallback? onTap;

  /// Compact height (see the class doc) with 12 dp corners on touch shells.
  final bool dense;

  /// Spoken name instead of the visible label ("Thêm 10 phút" for "+10 ph").
  /// Keep a tooltip visual only (`excludeFromSemantics`).
  final String? semanticLabel;

  /// The chip sits on a raised surface (`surfaceContainerHigh`: a filter
  /// panel); an unselected chip then uses `surfaceContainerHighest` so it does
  /// not sink into the background.
  final bool onRaised;

  /// A [selected] chip is tinted `secondaryContainer`; false keeps the
  /// plain pill and says the state only to screen readers (a caller that
  /// shows it another way, such as an icon turning `primary`).
  final bool tintWhenSelected;

  /// Widget after the label of a [KChip.static] (its own action).
  final Widget? trailing;

  /// Outline instead of fill (a [KChip] that is not selected, and [KChip.tag]).
  final bool outlined;

  /// What the fill says ([KChip.tag] only).
  final KTagTone tone;
  final bool _interactive;
  final bool _tag;
  final bool _token;

  static const double _denseDesktopHeight = 32;
  static const double _denseTouchHeight = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_tag) return _buildTag(context, scheme);
    if (_token) return _buildToken(context, scheme);
    final touch = FormFactor.of(context) == FormFactor.mobile;
    final minHeight = dense
        ? (touch ? _denseTouchHeight : _denseDesktopHeight)
        : (touch ? KLayout.minTarget : KLayout.minTargetDesktop);
    final tinted = selected && tintWhenSelected;
    final fg = tinted ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: KSpace.x4,
          end: trailing == null ? KSpace.x4 : KSpace.x2,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: KIconSize.xs),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const KGap(KSpace.x2)],
                Flexible(
                  child: ExcludeSemantics(
                    excluding: semanticLabel != null,
                    child: label,
                  ),
                ),
                if (trailing != null) ...[const KGap(KSpace.x2), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
    final radius = dense && touch ? KRadius.sm : KRadius.full;
    final ringed = outlined && !tinted;
    final pill = Material(
      color: ringed
          ? Colors.transparent
          : tinted
          ? scheme.secondaryContainer
          : onRaised
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerHigh,
      shape: ringed
          ? RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: scheme.outlineVariant),
            )
          : KShape.of(radius),
      clipBehavior: Clip.antiAlias,
      child: _interactive
          ? InkWell(onTap: enabled ? onTap : null, child: content)
          : content,
    );
    if (!_interactive) return pill;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticLabel,
      child: Opacity(opacity: enabled ? 1 : 0.5, child: pill),
    );
  }

  Widget _buildToken(BuildContext context, ColorScheme scheme) {
    final fg = scheme.onSurfaceVariant;
    final pill = Material(
      type: MaterialType.transparency,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_tokenRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tokenHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _tokenPadding),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: ExcludeSemantics(
                excluding: semanticLabel != null,
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontSize: 12,
                    fontFamily: KFont.mono,
                    fontFamilyFallback: KFont.monoFallback,
                  ),
                  maxLines: 1,
                  child: label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: pill,
        ),
      ),
    );
  }

  static const double _tokenHeight = 28;
  static const double _tokenRadius = 8;
  static const double _tokenPadding = 10;

  Widget _buildTag(BuildContext context, ColorScheme scheme) {
    final (Color fill, Color on) = switch (tone) {
      KTagTone.neutral => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      KTagTone.highlight => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      KTagTone.muted => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      KTagTone.problem => (scheme.errorContainer, scheme.onErrorContainer),
    };
    final flat = outlined || !enabled;
    final fg = flat ? scheme.onSurfaceVariant : on;
    final large = KTagRow.isLarge(context);
    final tag = DecoratedBox(
      decoration: ShapeDecoration(
        color: flat ? null : fill,
        shape: RoundedRectangleBorder(
          borderRadius: _tagRadius,
          side: flat
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      child: ConstrainedBox(
        // Fixed 20 dp tall; from 1.5x text the label sets the height and the
        // width cap goes.
        constraints: BoxConstraints(
          minHeight: _tagHeight,
          maxWidth: large ? double.infinity : _tagMaxWidth,
        ),
        child: Padding(
          // 8 dp from the edge for both looks (the outline takes 1 dp of it).
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
          // Shrink to the label; the extra height of the 20 dp box is split
          // evenly above and below it.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: DefaultTextHeightBehavior(
              textHeightBehavior: const TextHeightBehavior(
                leadingDistribution: TextLeadingDistribution.even,
              ),
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: fg),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: icon == null
                    ? label
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconTheme.merge(
                            data: IconThemeData(color: fg, size: _tagIconSize),
                            child: icon!,
                          ),
                          const KGap(KSpace.x1),
                          Flexible(child: label),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    return enabled ? tag : Opacity(opacity: 0.6, child: tag);
  }

  static const double _tagIconSize = 12;
  static const double _tagHeight = 20;
  static const double _tagMaxWidth = 154;
  static const BorderRadius _tagRadius = BorderRadius.all(Radius.circular(6));
}

/// The meta line of a list row: [fixed] chips keep their width, [shrinking]
/// chips (the author, then any tail) give way with an ellipsis; it never
/// wraps. From 1.5x text everything wraps like words instead. Gap 6. Needs a
/// bounded width.
class KTagRow extends StatelessWidget {
  const KTagRow({super.key, this.fixed = const [], required this.shrinking});

  final List<Widget> fixed;
  final List<Widget> shrinking;

  /// From this text scale the chips grow and may wrap.
  static const double _largeScale = 1.5;

  static const double _gap = 6;

  /// Whether the text is scaled enough for the wrapping layout.
  static bool isLarge(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(11) / 11 >= _largeScale;

  @override
  Widget build(BuildContext context) {
    if (isLarge(context)) {
      return Wrap(
        spacing: _gap,
        runSpacing: KSpace.x1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [...fixed, ...shrinking],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _gap,
      children: [
        ...fixed,
        for (final c in shrinking) Flexible(child: c),
      ],
    );
  }
}
