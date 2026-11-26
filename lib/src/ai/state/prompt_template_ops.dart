import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/settings/builtin_templates.dart';
import '../domain/settings/prompt_template.dart';
import 'ai_settings_providers.dart';

/// Edits of the prompt template list (`ai.prompts`). Every method reads the
/// current list, changes a copy and writes it back; an invalid change throws
/// [ArgumentError] before anything is written.
class PromptTemplateOps {
  PromptTemplateOps({required this._read, required this._write});

  final List<PromptTemplate> Function() _read;
  final Future<void> Function(List<PromptTemplate>) _write;

  /// Appends a custom template.
  Future<void> add({required String label, required String body}) async {
    final t = PromptTemplate(label: label.trim(), body: body.trim());
    t.validate();
    await _write([..._read(), t]);
  }

  /// Replaces the label and body of the template at [index]. A builtin
  /// becomes edited, so a later restore leaves it alone.
  Future<void> edit(
    int index, {
    required String label,
    required String body,
  }) async {
    final list = [..._read()];
    final old = _at(list, index);
    if (old.isUnknown) {
      throw ArgumentError.value(index, 'index', 'is not an editable template');
    }
    final t = old.copyWith(
      label: label.trim(),
      body: body.trim(),
      edited: old.isBuiltin ? true : old.edited,
    )..validate();
    list[index] = t;
    await _write(list);
  }

  /// Removes the template at [index]. A deleted builtin comes back with
  /// [restoreDefaults].
  Future<void> delete(int index) async {
    final list = [..._read()];
    _at(list, index);
    list.removeAt(index);
    await _write(list);
  }

  /// Moves the template at [oldIndex] to [newIndex], the way
  /// `ReorderableListView.onReorder` reports it (a move down passes the index
  /// before the removal).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [..._read()];
    _at(list, oldIndex);
    if (newIndex < 0 || newIndex > list.length) {
      throw RangeError.range(newIndex, 0, list.length, 'newIndex');
    }
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(target, list.removeAt(oldIndex));
    await _write(list);
  }

  /// Turns the template at [index] on or off.
  Future<void> toggle(int index, {required bool enabled}) async {
    final list = [..._read()];
    final old = _at(list, index);
    if (old.isUnknown) {
      throw ArgumentError.value(index, 'index', 'is not a template');
    }
    list[index] = old.copyWith(enabled: enabled);
    await _write(list);
  }

  /// Adds back, at the end and in default order, the builtins that are not in
  /// the list. Builtins that are there (edited or not, on or off) and every
  /// other item stay as they are.
  Future<void> restoreDefaults() async {
    final list = _read();
    final present = {for (final t in list) t.key};
    final missing = [
      for (final key in BuiltinTemplateKeys.all)
        if (!present.contains(key)) PromptTemplate(key: key),
    ];
    if (missing.isEmpty) return;
    await _write([...list, ...missing]);
  }

  PromptTemplate _at(List<PromptTemplate> list, int index) {
    if (index < 0 || index >= list.length) {
      throw RangeError.index(index, list, 'index');
    }
    return list[index];
  }
}

/// The editor of `ai.prompts`. Reads the notifier when a method runs, so one
/// instance stays valid while the list changes.
final promptTemplateOpsProvider = Provider<PromptTemplateOps>(
  (ref) => PromptTemplateOps(
    read: () => ref.read(aiPromptsProvider),
    write: (list) => ref.read(aiPromptsProvider.notifier).set(list),
  ),
);
