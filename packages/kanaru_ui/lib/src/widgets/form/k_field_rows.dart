import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_space.dart';
import 'k_field_row_view.dart';

/// Editable rows of short text: a **list** (one field per row) or a **map**
/// (a name field and a value field per row). One widget for both.
///
/// Each row has outlined 48 dp field(s) and a remove button; [addLabel] adds a
/// blank row and focuses it (disabled at [maxRows]). A map's value column is as
/// wide as the name column on a phone and 1.4 times as wide on desktop; from
/// 200 % text the two fields of a row stack, the remove button staying beside
/// the name. The caller spaces the block from its title (14 dp).
///
/// **Commit.** [onCommit] gets the rows that are not blank (white space only)
/// when a row loses focus, on Enter in a field and after a remove, only when
/// they differ from the last ones sent. The widget keeps the text being edited:
/// a new [values] from outside replaces the rows only when the content really
/// changed and no field has focus.
///
/// **Errors** use the position among the non-blank rows, the same order as
/// [onCommit] and [values]: [rowErrors] (a map: under the name field, with its
/// red outline), [invalidRows] (red outline on the row's fields, no line) and
/// [error], one line under the whole block. All text comes from the caller.
class KFieldRows extends StatefulWidget {
  /// A list of strings; [hint] is the placeholder of every field.
  KFieldRows.list({
    super.key,
    required List<String> values,
    required ValueChanged<List<String>> onCommit,
    required String this.hint,
    required this.addLabel,
    required this.removeTooltip,
    this.keyboard,
    this.maxRows = 50,
    this.enabled = true,
    this.error,
    this.invalidRows = const {},
  }) : labels = null,
       values = [
         for (final v in values) [v],
       ],
       rowErrors = const {},
       onCommit = ((rows) => onCommit([for (final r in rows) r[0]]));

  /// A table of name → value pairs; [nameLabel] and [valueLabel] float inside
  /// the two fields.
  KFieldRows.map({
    super.key,
    required List<(String, String)> values,
    required ValueChanged<List<(String, String)>> onCommit,
    required String nameLabel,
    required String valueLabel,
    required this.addLabel,
    required this.removeTooltip,
    this.maxRows = 50,
    this.enabled = true,
    this.error,
    this.invalidRows = const {},
    this.rowErrors = const {},
  }) : labels = [nameLabel, valueLabel],
       hint = null,
       keyboard = null,
       values = [
         for (final (n, v) in values) [n, v],
       ],
       onCommit = ((rows) => onCommit([for (final r in rows) (r[0], r[1])]));

  /// Committed rows, one list of column texts per row.
  final List<List<String>> values;
  final void Function(List<List<String>> rows) onCommit;
  final List<String>? labels;
  final String? hint;
  final String addLabel;
  final String removeTooltip;
  final TextInputType? keyboard;
  final int maxRows;

  /// False dims every field and button.
  final bool enabled;
  final String? error;
  final Set<int> invalidRows;
  final Map<int, String> rowErrors;

  @override
  State<KFieldRows> createState() => _KFieldRowsState();
}

class _KFieldRowsState extends State<KFieldRows> {
  final _rows = <FieldRowModel>[];
  var _nextId = 0;

  /// What [KFieldRows.onCommit] got last (or the initial values).
  List<List<String>> _sent = const [];

  int get _columns => widget.labels?.length ?? 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(KFieldRows old) {
    super.didUpdateWidget(old);
    if (!sameRows(old.values, widget.values) &&
        !sameRows(_texts(), widget.values) &&
        !_rows.any((r) => r.hasFocus)) {
      _discard(_rows.toList());
      _rows.clear();
      _load();
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _load() {
    _sent = [
      for (final v in widget.values) [...v],
    ];
    for (final v in widget.values) {
      _rows.add(_make(v));
    }
  }

  FieldRowModel _make(List<String> texts) {
    final row = FieldRowModel(_nextId++, texts);
    for (final node in row.nodes) {
      node.addListener(() => _focusChanged(row));
    }
    return row;
  }

  /// A removed row is still in this frame's tree: dispose after it.
  void _discard(List<FieldRowModel> rows) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final row in rows) {
        row.dispose();
      }
    });
  }

  List<List<String>> _texts() => [
    for (final row in _rows)
      if (!row.blank) row.texts,
  ];

  /// Tab inside a row moves focus between its fields in one step: look after
  /// that step, not during it.
  void _focusChanged(FieldRowModel row) {
    scheduleMicrotask(() {
      if (mounted && _rows.contains(row) && !row.hasFocus) _commit();
    });
  }

  void _commit() {
    final rows = _texts();
    if (sameRows(rows, _sent)) return;
    _sent = rows;
    widget.onCommit(rows);
  }

  void _add() {
    final row = _make([for (var i = 0; i < _columns; i++) '']);
    setState(() => _rows.add(row));
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rows.contains(row)) row.nodes.first.requestFocus();
    });
  }

  void _remove(FieldRowModel row) {
    setState(() => _rows.remove(row));
    _discard([row]);
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    // Two fields side by side do not read at 200 % text on a phone.
    final stacked =
        _columns == 2 && MediaQuery.textScalerOf(context).scale(14) >= 28;
    final wide = FormFactor.of(context) == FormFactor.desktop;
    final flexes = _columns == 2 ? [10, wide ? 14 : 10] : const [1];
    // Position among the non-blank rows, -1 for a blank one.
    var counted = 0;
    final positions = [for (final row in _rows) row.blank ? -1 : counted++];
    final error = widget.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rows.length; i++) ...[
          FieldRowView(
            key: ValueKey(_rows[i].id),
            model: _rows[i],
            labels: widget.labels,
            hint: widget.hint,
            flexes: flexes,
            stacked: stacked,
            enabled: widget.enabled,
            keyboard: widget.keyboard,
            invalid: widget.invalidRows.contains(positions[i]),
            error: widget.rowErrors[positions[i]],
            removeTooltip: widget.removeTooltip,
            onRemove: () => _remove(_rows[i]),
            onSubmitted: _commit,
          ),
          SizedBox(height: stacked ? KSpace.x5 : KSpace.x3),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: widget.enabled && _rows.length < widget.maxRows
                ? _add
                : null,
            icon: const Icon(KIcons.add),
            label: Text(widget.addLabel),
          ),
        ),
        if (error != null && error.isNotEmpty) FieldRowsError(error),
      ],
    );
  }
}
