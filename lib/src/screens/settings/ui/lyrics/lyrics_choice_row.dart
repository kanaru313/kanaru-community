import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../platform/state/settings_providers.dart';

/// One option of a [LyricsChoiceRow]: its name, an optional line under it and
/// an optional icon (a picker whose options all have one shows icon rows).
class LyricsChoice<T> {
  const LyricsChoice(this.value, this.label, {this.subtitle, this.icon});

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// A value row for one lyrics setting: the line under the title is the
/// current choice, a tap opens the picker (anchored on desktop) with an
/// optional visible [caption] under its title. The choice applies at once,
/// unless [confirm] asks first: it runs before the picker closes, and false
/// keeps the picker open and the old value.
class LyricsChoiceRow<T> extends ConsumerStatefulWidget {
  const LyricsChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.provider,
    required this.choices,
    this.caption,
    this.confirm,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final NotifierProvider<SettingNotifier<T>, T> provider;
  final List<LyricsChoice<T>> choices;

  /// Asked with the tapped value before the picker closes; null always agrees.
  final Future<bool> Function(T value)? confirm;

  @override
  ConsumerState<LyricsChoiceRow<T>> createState() => _LyricsChoiceRowState<T>();
}

class _LyricsChoiceRowState<T> extends ConsumerState<LyricsChoiceRow<T>> {
  final _anchor = GlobalKey();

  Future<void> _pick(T current) async {
    // Taken before the await: the picker may outlive this row.
    final notifier = ref.read(widget.provider.notifier);
    final theme = Theme.of(context);
    final caption = widget.caption;
    final chosen = await showSelectionPicker<T>(
      context,
      anchor: _anchor,
      anchorAlign: KAnchorAlign.end,
      title: Text(widget.title),
      header: caption == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                KSpace.x4,
                0,
                KSpace.x4,
                KSpace.x2,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                child: Text(caption),
              ),
            ),
      selected: current,
      confirm: widget.confirm,
      options: [
        for (final c in widget.choices)
          SelectionOption<T>(
            value: c.value,
            title: Text(c.label),
            leading: c.icon == null ? null : Icon(c.icon),
            subtitle: c.subtitle == null ? null : Text(c.subtitle!),
          ),
      ],
    );
    if (chosen != null && chosen != current) await notifier.set(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(widget.provider);
    final name = widget.choices
        .where((c) => c.value == current)
        .map((c) => c.label)
        .firstOrNull;
    return SetupValueRow(
      anchorKey: _anchor,
      icon: widget.icon,
      title: Text(widget.title),
      value: Text(name ?? ''),
      onTap: () => _pick(current),
    );
  }
}
