import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// One font of the Font page: its name and a sample line, both drawn in the
/// font's own [family]. The active font gets a plain tick and a bold primary
/// name, without a tinted row (a deliberate exception to the selection rows).
///
/// A null [onTap] makes the row inert but keeps its full contrast (the active
/// font, or a font that cannot be used yet).
class FontChoiceRow extends StatelessWidget {
  const FontChoiceRow({
    super.key,
    required this.title,
    required this.sample,
    required this.family,
    this.defaultSuffix,
    this.selected = false,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String sample;

  /// Family the name and the sample are drawn in.
  final String family;

  /// Soft text after the name (for example "· default").
  final String? defaultSuffix;

  /// The font in use: shows the tick instead of [trailing].
  final bool selected;

  /// What a font that is not in use shows at the end (size and download,
  /// spinner, delete). Empty for built-in fonts.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nameStyle = textTheme.bodyLarge!.copyWith(
      fontFamily: family,
      fontWeight: selected ? FontWeight.w700 : null,
      color: selected ? scheme.primary : null,
    );
    final suffix = defaultSuffix;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: SetupRowFrame(
          title: Text.rich(
            TextSpan(
              text: title,
              children: [
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            style: nameStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            sample,
            style: textTheme.bodyMedium!.copyWith(
              fontFamily: family,
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: selected
              ? Icon(KIcons.check, color: scheme.primary)
              : trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
