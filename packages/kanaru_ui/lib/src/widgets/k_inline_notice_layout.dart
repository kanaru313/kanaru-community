import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';

/// Arrangement of the parts of a `KInlineNotice`: icon, text, buttons and ×.
/// Used by the notice only; not exported.
class KInlineNoticeLayout extends StatelessWidget {
  const KInlineNoticeLayout({
    super.key,
    required this.icon,
    required this.text,
    required this.underText,
    required this.stacked,
    required this.compact,
    this.action,
    this.second,
    this.dismiss,
  });

  final Widget icon;
  final Widget text;
  final Widget? action;
  final Widget? second;
  final Widget? dismiss;

  /// Buttons sit in a row under the text (the × stays at the top right).
  final bool underText;

  /// One button under the text, at the end, because the text scale is large.
  final bool stacked;
  final bool compact;

  static const double _gap = KSpace.x3;

  @override
  Widget build(BuildContext context) {
    if (underText) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (action != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: KSpace.x1,
                      bottom: compact ? 0 : KSpace.x1,
                    ),
                    child: Wrap(
                      spacing: KSpace.x2,
                      runSpacing: KSpace.x1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [action!, ?second],
                    ),
                  ),
              ],
            ),
          ),
          ?dismiss,
        ],
      );
    }
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: _gap),
              Expanded(child: text),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: _gap),
        Expanded(child: text),
        if (action != null) ...[const SizedBox(width: _gap), action!],
      ],
    );
  }
}
