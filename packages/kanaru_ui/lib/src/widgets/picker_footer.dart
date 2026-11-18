import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';

/// Fixed footer of a picker. With a [note]: one row, vertically centred, the
/// note (`bodySmall`) taking the remaining width on the left and the [buttons]
/// side by side on the right at their natural width (capped at 70 % of the
/// row); the buttons never stack. When the cap binds a button label may wrap
/// inside its button, and the note wraps within its own area
/// (never cut). Without a note the [buttons] are right-aligned and wrap onto a
/// second line instead of overflowing. A line above it when [border] is set.
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
    final noteStyle = Theme.of(context).textTheme.bodySmall!
        .copyWith(color: scheme.onSurfaceVariant);
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
            : LayoutBuilder(
                builder: (context, constraints) => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: noteStyle,
                        child: note!,
                      ),
                    ),
                    const SizedBox(width: KSpace.x2),
                    // Natural width, capped at 70 % of the row: a long note
                    // wraps in the rest instead of squeezing the labels, and
                    // labels wrap only when the cap binds.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (var i = 0; i < buttons.length; i++) ...[
                            if (i > 0) const SizedBox(width: KSpace.x2),
                            Flexible(child: buttons[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
