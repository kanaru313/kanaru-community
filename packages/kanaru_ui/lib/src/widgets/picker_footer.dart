import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';

/// Fixed footer of a picker: an optional [note] on the left (`bodySmall`),
/// [buttons] right-aligned, wrapping onto a second line instead of overflowing
/// when the labels are long or the text is large. A line above it when
/// [border] is set.
class PickerFooter extends StatelessWidget {
  const PickerFooter({
    super.key,
    required this.buttons,
    this.note,
    this.border = true,
  });

  final List<Widget> buttons;
  final Widget? note;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wrap = Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: KSpace.x2,
        runSpacing: KSpace.x1,
        children: buttons,
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: border
            ? Border(top: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x4,
          KSpace.x2,
          KSpace.x4,
          KSpace.x1,
        ),
        child: note == null
            ? wrap
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      child: note!,
                    ),
                  ),
                  const SizedBox(width: KSpace.x2),
                  Expanded(flex: 3, child: wrap),
                ],
              ),
      ),
    );
  }
}
