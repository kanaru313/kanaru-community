import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Up to two lines, then an ellipsis (long names, 200 % text).
class CoverText extends StatelessWidget {
  const CoverText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
}

class CoverPill extends StatelessWidget {
  const CoverPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: KRadius.full,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x2,
          vertical: KSpace.x1 / 2,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onTertiaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class CoverGroupTitle extends StatelessWidget {
  const CoverGroupTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KSpace.x4,
      KSpace.x4,
      KSpace.x4,
      KSpace.x1,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class CoverMessage extends StatelessWidget {
  const CoverMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KSpace.x4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
