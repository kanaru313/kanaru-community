import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../plugins/domain/config/config_field.dart';
import 'translate_page_parts.dart';
import 'translate_tune_select.dart';

/// One select of "Tinh chỉnh AI" (Model, Phong cách): the section title with
/// the option count, then the chosen option as a tonal field (title, its
/// subtitle, ▾) that opens the select. [error] is the line of a refused
/// write.
class TranslateTuneField extends StatelessWidget {
  const TranslateTuneField({
    super.key,
    required this.sectionTitle,
    required this.field,
    required this.value,
    required this.onOpen,
    this.error,
  });

  final String sectionTitle;
  final SelectField field;
  final String? value;
  final VoidCallback onOpen;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final chosen = field.options.where((o) => o.value == value).firstOrNull;
    final shown =
        chosen ??
        (value == null || value!.isEmpty
            ? null
            : ConfigOption(value: value!, title: value!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslateSectionTitle(sectionTitle, count: field.options.length),
        if (shown != null)
          KPickerField(
            title: tuneOptionTitle(field, shown),
            subtitle: shown.subtitle,
            semanticLabel: '$sectionTitle: ${shown.title}',
            onTap: onOpen,
          ),
        if (error != null) TranslateCaption(error!, error: true),
      ],
    );
  }
}
