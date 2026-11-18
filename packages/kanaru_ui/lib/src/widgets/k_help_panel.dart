import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';

/// Body of the bottom sheet a long [KHelpIcon] message opens in.
class KHelpSheetBody extends StatelessWidget {
  const KHelpSheetBody({
    super.key,
    required this.message,
    this.title,
    this.closeLabel,
  });

  final String message;
  final String? title;
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.x6, KSpace.x2, KSpace.x6, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const KGap(KSpace.x2),
          ],
          Flexible(
            child: SingleChildScrollView(
              child: Text(message, style: textTheme.bodyMedium),
            ),
          ),
          const KGap(KSpace.x2),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                closeLabel ??
                    MaterialLocalizations.of(context).closeButtonLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The floating card of a [KHelpIcon] popover / panel: fades in (instantly
/// with animations off), [title] only for the long panel.
class KHelpPopoverCard extends StatelessWidget {
  const KHelpPopoverCard({
    super.key,
    required this.message,
    required this.maxWidth,
    this.title,
  });

  final String message;
  final String? title;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate ? KMotion.fast : Duration.zero,
      curve: KMotion.emphasized,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Material(
          elevation: 3,
          color: scheme.surfaceContainerHigh,
          shape: KShape.of(KRadius.md, continuous: true),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(KSpace.x4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const KGap(KSpace.x2),
                  ],
                  Text(message, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
