import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../foundation/text/text_fold.dart';
import '../../../../plugins/domain/config/config_field.dart';

/// Lists longer than this get a search box.
const int tuneSearchFrom = 8;

/// The small "mặc định" tag after an option's title.
class TuneDefaultTag extends StatelessWidget {
  const TuneDefaultTag({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: KRadius.full,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x2,
          vertical: KSpace.x1 / 2,
        ),
        child: Text(
          AppLocalizations.of(context).lyricsTranslateDefaultTag,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// An option's title with the default tag when it is the field's default.
Widget tuneOptionTitle(SelectField field, ConfigOption option) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Flexible(child: Text(option.title)),
    if (option.value == field.defaultValue) ...[
      const KGap(KSpace.x2),
      const TuneDefaultTag(),
    ],
  ],
);

/// Opens the select of [field] as a picker (a search box over
/// [tuneSearchFrom] options); [onPick] saves the choice. A stored value the
/// field does not list (a choice of the user's own) is shown as a row too.
/// Resolves when the picker closes.
Future<void> showTuneSelect(
  BuildContext context, {
  required String title,
  required SelectField field,
  required String? selected,
  required Future<void> Function(String value) onPick,
}) {
  final l10n = AppLocalizations.of(context);
  final listed = field.options;
  final options = [
    ...listed,
    if (selected != null &&
        selected.isNotEmpty &&
        !listed.any((o) => o.value == selected))
      ConfigOption(value: selected, title: selected),
  ];
  SelectionOption<String> optionOf(ConfigOption o) => SelectionOption<String>(
    value: o.value,
    title: tuneOptionTitle(field, o),
    subtitle: o.subtitle == null ? null : Text(o.subtitle!),
  );
  final searchable = options.length > tuneSearchFrom;
  final live = ValueNotifier(
    SelectionPickerState<String>(
      options: [for (final o in options) optionOf(o)],
      selected: selected,
    ),
  );
  final search = TextEditingController();
  void filter(String query) {
    final matches = foldedQuery(query);
    live.value = SelectionPickerState<String>(
      options: [
        for (final o in options)
          if (matches('${o.title} ${o.subtitle ?? ''}')) optionOf(o),
      ],
      selected: selected,
    );
  }

  return showSelectionPicker<String>(
    context,
    title: Text(title),
    header: searchable
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x1,
              KSpace.x4,
              KSpace.x2,
            ),
            child: KFilterField(
              controller: search,
              hint: l10n.lyricsTranslateSearchHint(options.length),
              persistent: true,
              autofocus: false,
              onChanged: filter,
              onClose: () {},
            ),
          )
        : null,
    options: live.value.options,
    selected: selected,
    live: live,
    confirm: (value) async {
      await onPick(value);
      return true;
    },
  ).whenComplete(() {
    live.dispose();
    search.dispose();
  });
}

/// The test of a search box: every word of [query] is in the text, ignoring
/// case and diacritics.
bool Function(String) foldedQuery(String query) {
  final words = foldDiacritics(query)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList(growable: false);
  return (text) {
    final folded = foldDiacritics(text);
    return words.every(folded.contains);
  };
}
