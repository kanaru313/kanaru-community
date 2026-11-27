import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../ai/domain/settings/prompt_template.dart';
import '../../../ai/domain/variables/template_analysis.dart';
import '../../../ai/state/ai_settings_providers.dart';
import '../../../ai/state/prompt_template_ops.dart';

final _log = Logger('settings.ai_prompt_editor');

int _chars(String s) => s.runes.length;

/// The prompt the editor opened on: a place in the stored list ([index], null
/// for a new prompt) and the texts it started with. A builtin's [key] is set
/// and its texts are the l10n ones the list shows.
@immutable
class PromptEditorTarget {
  const PromptEditorTarget({
    this.index,
    this.key,
    this.label = '',
    this.body = '',
  });

  final int? index;
  final String? key;
  final String label;
  final String body;

  bool get isNew => index == null;
  bool get isBuiltin => key != null;

  @override
  bool operator ==(Object other) =>
      other is PromptEditorTarget &&
      other.index == index &&
      other.key == key &&
      other.label == label &&
      other.body == body;

  @override
  int get hashCode => Object.hash(index, key, label, body);
}

/// What the user has typed so far.
@immutable
class PromptEditorState {
  const PromptEditorState({
    required this.target,
    required this.label,
    required this.body,
  });

  final PromptEditorTarget target;
  final String label;
  final String body;

  /// The texts differ from the ones the editor opened with.
  bool get dirty => label != target.label || body != target.body;

  /// Both fields have text and fit their limits (in code points, as the
  /// stored template counts).
  bool get valid =>
      label.trim().isNotEmpty &&
      body.trim().isNotEmpty &&
      _chars(label) <= promptLabelMaxChars &&
      _chars(body) <= promptBodyMaxChars;

  /// Save is on when the texts are valid and [analysis] finds no unknown
  /// variable. A variable of a tool group that is off only warns.
  bool canSave(TemplateAnalysis analysis) => valid && !analysis.invalidAsSaved;

  PromptEditorState copyWith({String? label, String? body}) =>
      PromptEditorState(
        target: target,
        label: label ?? this.label,
        body: body ?? this.body,
      );
}

/// Editor of one prompt template. Typing only changes this state; [save] and
/// [delete] go through [PromptTemplateOps], which marks an edited builtin so a
/// later restore leaves it alone.
class PromptEditor extends Notifier<PromptEditorState> {
  PromptEditor(this.target);

  final PromptEditorTarget target;

  @override
  PromptEditorState build() =>
      PromptEditorState(target: target, label: target.label, body: target.body);

  void setLabel(String value) {
    if (value != state.label) state = state.copyWith(label: value);
  }

  void setBody(String value) {
    if (value != state.body) state = state.copyWith(body: value);
  }

  /// Writes the prompt. False when it cannot be saved (invalid text, an
  /// unknown variable, the list changed under the editor) or the write threw;
  /// the editor then stays as it is. A builtin left unchanged writes nothing,
  /// so it keeps following the app language.
  Future<bool> save() async {
    final s = state;
    // Not through promptEditorAnalysisProvider: that one watches this
    // notifier, and a notifier may not read a provider that depends on it.
    final analysis = analyzeTemplate(
      s.body,
      (group) => ref.read(aiToolGroupProvider(group)),
    );
    if (!s.canSave(analysis)) return false;
    final index = target.index;
    if (index != null && !_stillThere(index)) return false;
    final ops = ref.read(promptTemplateOpsProvider);
    try {
      if (index == null) {
        await ops.add(label: s.label, body: s.body);
      } else if (_changedAsStored(s)) {
        await ops.edit(index, label: s.label, body: s.body);
      }
      return true;
    } on Object catch (e, st) {
      _log.warning('saving the prompt failed', e, st);
      return false;
    }
  }

  /// Removes the prompt from the list. False for a new prompt, when the list
  /// changed under the editor, or when the write threw.
  Future<bool> delete() async {
    final index = target.index;
    if (index == null || !_stillThere(index)) return false;
    final ops = ref.read(promptTemplateOpsProvider);
    try {
      await ops.delete(index);
      return true;
    } on Object catch (e, st) {
      _log.warning('deleting the prompt failed', e, st);
      return false;
    }
  }

  /// The ops store trimmed text, so a change of only spaces is no edit: a
  /// builtin stays unedited (and keeps following the app language).
  bool _changedAsStored(PromptEditorState s) =>
      s.label.trim() != target.label.trim() ||
      s.body.trim() != target.body.trim();

  /// The list still holds the template the editor opened (an index is only a
  /// place: a restore or a delete elsewhere may have moved things).
  bool _stillThere(int index) {
    final list = ref.read(aiPromptsProvider);
    if (index < 0 || index >= list.length) return false;
    final t = list[index];
    return !t.isUnknown && t.key == target.key;
  }
}

final promptEditorProvider =
    NotifierProvider.family<
      PromptEditor,
      PromptEditorState,
      PromptEditorTarget
    >(PromptEditor.new, isAutoDispose: true);

/// The `{{variables}}` of the typed prompt against the user's tool switches.
final promptEditorAnalysisProvider = Provider.autoDispose
    .family<TemplateAnalysis, PromptEditorTarget>((ref, target) {
      final body = ref.watch(
        promptEditorProvider(target).select((s) => s.body),
      );
      return analyzeTemplate(
        body,
        (group) => ref.watch(aiToolGroupProvider(group)),
      );
    });
