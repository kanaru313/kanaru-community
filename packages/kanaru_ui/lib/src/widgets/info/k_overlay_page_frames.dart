import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';

/// The header row: focus-transparent, so `viaKeyboard` can find its first
/// button through [node].
Widget _headerRow(FocusNode node, List<Widget> children) => Focus(
  focusNode: node,
  canRequestFocus: false,
  skipTraversal: true,
  child: Row(children: children),
);

Widget _title(ThemeData theme, String text) => Semantics(
  header: true,
  child: Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  ),
);

/// Full-screen page: `surface`, a 56 bar `[←] title · actions`, then [body].
class KOverlayPageFrame extends StatelessWidget {
  const KOverlayPageFrame({
    super.key,
    required this.headerNode,
    required this.title,
    required this.actions,
    required this.backTooltip,
    required this.onClose,
    required this.body,
  });

  final FocusNode headerNode;
  final String title;
  final List<Widget> actions;
  final String backTooltip;
  final VoidCallback onClose;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: _headerRow(headerNode, [
                const SizedBox(width: KSpace.x1),
                KIconButton(
                  tooltip: backTooltip,
                  icon: KIcons.back,
                  onPressed: onClose,
                ),
                const SizedBox(width: KSpace.x2),
                Expanded(child: _title(theme, title)),
                ...actions,
                const SizedBox(width: KSpace.x2),
              ]),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Centred box over a 45 % barrier: at most [maxWidth] x [maxHeight], 28
/// corners, a fixed header (the [header] or the title, [actions], ✕) with a
/// hairline, then [body]. A tap on the barrier calls [onClose].
class KOverlayBoxFrame extends StatelessWidget {
  const KOverlayBoxFrame({
    super.key,
    required this.headerNode,
    required this.title,
    required this.header,
    required this.actions,
    required this.closeTooltip,
    required this.onClose,
    required this.maxWidth,
    required this.maxHeight,
    required this.body,
  });

  final FocusNode headerNode;
  final String title;
  final Widget? header;
  final List<Widget> actions;
  final String closeTooltip;
  final VoidCallback onClose;
  final double maxWidth;
  final double maxHeight;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: const ColoredBox(color: Color(0x73000000)),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            // Swallows taps so they never reach the barrier.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Material(
                color: theme.colorScheme.surfaceContainerHigh,
                shape: KShape.of(KRadius.xl, continuous: true),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        KSpace.x6,
                        KSpace.x4,
                        KSpace.x4,
                        KSpace.x3,
                      ),
                      child: _headerRow(headerNode, [
                        Expanded(child: header ?? _title(theme, title)),
                        ...actions,
                        KIconButton(
                          tooltip: closeTooltip,
                          icon: KIcons.close,
                          onPressed: onClose,
                        ),
                      ]),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Flexible(child: body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
