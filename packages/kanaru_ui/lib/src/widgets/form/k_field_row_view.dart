import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';
import 'k_text_field_row.dart';

/// The live state of one row of a `KFieldRows`: a controller and a focus node
/// per column. Not exported.
class FieldRowModel {
  FieldRowModel(this.id, List<String> texts)
    : controllers = [for (final t in texts) TextEditingController(text: t)],
      nodes = [for (final _ in texts) FocusNode()];

  final int id;
  final List<TextEditingController> controllers;
  final List<FocusNode> nodes;

  List<String> get texts => [for (final c in controllers) c.text];

  /// Nothing but white space: such a row does not count.
  bool get blank => controllers.every((c) => c.text.trim().isEmpty);

  bool get hasFocus => nodes.any((n) => n.hasFocus);

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final n in nodes) {
      n.dispose();
    }
  }
}

/// One row: its field(s) side by side, or one over the other when [stacked],
/// and the remove button beside the first field. Not exported.
class FieldRowView extends StatelessWidget {
  const FieldRowView({
    super.key,
    required this.model,
    required this.labels,
    required this.hint,
    required this.flexes,
    required this.stacked,
    required this.enabled,
    required this.keyboard,
    required this.invalid,
    required this.error,
    required this.removeTooltip,
    required this.onRemove,
    required this.onSubmitted,
  });

  final FieldRowModel model;

  /// Floating label per column (a table), or null.
  final List<String>? labels;

  /// Placeholder of the single column of a list.
  final String? hint;
  final List<int> flexes;
  final bool stacked;
  final bool enabled;
  final TextInputType? keyboard;
  final bool invalid;

  /// Under the first field; also draws its red outline.
  final String? error;
  final String removeTooltip;
  final VoidCallback onRemove;
  final VoidCallback onSubmitted;

  static const double gap = KSpace.x2;
  static const double stackGap = KSpace.x5;

  Widget _field(int column) => KTextFieldRow(
    label: labels?[column],
    hint: labels == null ? hint : null,
    controller: model.controllers[column],
    focusNode: model.nodes[column],
    dense: true,
    enabled: enabled,
    keyboard: keyboard,
    invalid: invalid,
    error: column == 0 ? error : null,
    onSubmitted: (_) => onSubmitted(),
  );

  @override
  Widget build(BuildContext context) {
    final count = model.controllers.length;
    final remove = SizedBox(
      height: KTextFieldRow.denseHeight,
      child: Center(
        child: KIconButton(
          icon: KIcons.close,
          size: KIconSize.sm,
          tooltip: removeTooltip,
          onPressed: enabled ? onRemove : null,
        ),
      ),
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: stackGap),
            // The remove button stays beside the first field.
            if (i == 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(0)),
                  remove,
                ],
              )
            else
              _field(i),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          Expanded(flex: flexes[i], child: _field(i)),
        ],
        remove,
      ],
    );
  }
}

/// Whether two lists of rows hold the same texts. Not exported.
bool sameRows(List<List<String>> a, List<List<String>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].length != b[i].length) return false;
    for (var j = 0; j < a[i].length; j++) {
      if (a[i][j] != b[i][j]) return false;
    }
  }
  return true;
}

/// The one error line under a whole block of rows. Not exported.
class FieldRowsError extends StatelessWidget {
  const FieldRowsError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: KSpace.x4,
        right: KSpace.x4,
        top: KSpace.x1,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
