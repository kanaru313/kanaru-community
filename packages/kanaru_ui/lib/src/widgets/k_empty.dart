import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_space.dart';

/// Empty state: icon, one sentence and an optional action.
class KEmpty extends StatelessWidget {
  const KEmpty({
    super.key,
    required this.icon,
    required this.message,
    this.messageIcon,
    this.messageIconLabel,
    this.title,
    this.action,
    this.actions = const [],
  }) : assert(actions.length <= 2, 'at most two actions');

  final IconData icon;

  /// One sentence. When [messageIcon] is set, the first [iconToken] in it is
  /// replaced by that icon, drawn inline in the theme's accent colour (a
  /// text glyph like a heart would come from the emoji font instead).
  final String message;

  /// Icon drawn where [iconToken] stands in [message].
  final IconData? messageIcon;

  /// Spoken in place of the icon; the sentence reads as one text.
  final String? messageIconLabel;

  /// Placeholder for [messageIcon] inside [message].
  static const iconToken = '[icon]';

  /// Bold line above [message].
  final String? title;
  final Widget? action;

  /// Up to two buttons after [message] (primary first), side by side and
  /// wrapping when the width is short.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Scrolls when the content outgrows the space (long text at a large text
    // scale on a short phone); centred while it fits.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        primary: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
          ),
          child: Center(child: _content(context, scheme)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(KSpace.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: KSpace.x3,
        children: [
          Icon(icon, size: KIconSize.hero, color: scheme.onSurfaceVariant),
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          _message(context, scheme),
          ?action,
          if (actions.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: KSpace.x3,
              runSpacing: KSpace.x2,
              children: actions,
            ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, ColorScheme scheme) {
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: scheme.onSurfaceVariant);
    final at = message.indexOf(iconToken);
    if (messageIcon == null || at < 0) {
      return Text(message, textAlign: TextAlign.center, style: style);
    }
    final before = message.substring(0, at);
    final after = message.substring(at + iconToken.length);
    return Semantics(
      label: '$before${messageIconLabel ?? ''}$after',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: before),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                messageIcon,
                size: (style?.fontSize ?? 16) * 1.25,
                color: scheme.primary,
              ),
            ),
            TextSpan(text: after),
          ],
        ),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
