import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';
import 'multi_selection_model.dart';
import 'multi_selection_parts.dart';
import 'selection_row.dart';

/// One entry of the scrolling list of a multi picker (see
/// [MultiSelectionView] for the order). Rows are blocked while [busy].
Widget buildMultiEntry<T>(
  BuildContext context, {
  required MultiSelectionView<T> view,
  required int index,
  required bool busy,
  required bool actionBusy,
  required ValueChanged<T> onToggle,
  required VoidCallback onToggleAll,
  required VoidCallback onAction,
  bool dense = false,
  String? selectAllLabel,
  String Function(int n, int total)? selectedCountLabel,
  String? minSelectedNote,
  Widget? banner,
  Widget? emptyNote,
  Widget? listFooter,
}) {
  final entry = view.entries[index];
  switch (entry.kind) {
    case MultiKind.banner:
      return banner!;
    case MultiKind.selectAll:
      final picked = view.picks.length;
      final total = view.enabledValues.length;
      return SelectionRow(
        dense: dense,
        multi: true,
        // Icon options: plain tick on the right (no leading slot); text
        // options: mark at the start.
        plainMark: view.iconRows,
        title: Text(selectAllLabel!),
        subtitle: selectedCountLabel == null
            ? null
            : Text(selectedCountLabel(picked, total)),
        selected: picked > 0,
        partial: picked > 0 && picked < total,
        enabled: !view.selectAllLocked,
        onTap: busy ? null : onToggleAll,
      );
    case MultiKind.divider:
      return ExcludeSemantics(
        child: Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    case MultiKind.action:
      return MultiSelectionActionRow<T>(
        action: view.action!,
        onTap: busy || actionBusy ? null : onAction,
      );
    case MultiKind.empty:
      return Padding(
        padding: const EdgeInsets.all(KSpace.x6),
        child: emptyNote,
      );
    case MultiKind.footer:
      return listFooter!;
    case MultiKind.option:
      final o = entry.option!;
      final locked = view.isLocked(o.value);
      return SelectionRow(
        dense: dense,
        multi: true,
        title: o.title,
        subtitle: locked && minSelectedNote != null
            ? _withNote(o.subtitle, minSelectedNote)
            : o.subtitle,
        leading: o.leading,
        hint: o.hint,
        enabled: o.enabled && !locked,
        selected: view.chosen.contains(o.value),
        onTap: busy ? null : () => onToggle(o.value),
      );
  }
}

/// [subtitle] with [note] after it on the same line ("mp3, mp2 · note"; just
/// [note] when there is no subtitle).
Widget _withNote(Widget? subtitle, String note) {
  if (subtitle is Text && subtitle.data != null) {
    return Text('${subtitle.data} · $note');
  }
  return subtitle == null
      ? Text(note)
      : Text.rich(
          TextSpan(
            children: [
              WidgetSpan(child: subtitle),
              TextSpan(text: ' · $note'),
            ],
          ),
        );
}

/// Runs [confirm] and says whether it answered true in time. Past [limit]
/// (null = no limit) the answer is false and a late result is ignored; an
/// error is reported through [FlutterError.reportError] and counts as false.
Future<bool> runBoundedConfirm(
  Future<bool> Function() confirm,
  Duration? limit,
) async {
  try {
    // Re-wrapped so the future is a plain `Future<bool>` whatever closure the
    // caller passed (`timeout` needs that).
    var pending = Future<bool>.value(confirm());
    if (limit != null) {
      pending = pending.timeout(limit, onTimeout: () => false);
    }
    return await pending;
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'kanaru_ui',
        context: ErrorDescription('while confirming a multi selection'),
      ),
    );
    return false;
  }
}
