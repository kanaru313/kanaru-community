import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/settings/prompt_template.dart';
import '../../../../ai/domain/variables/variable_catalog.dart';
import '../../../../ai/state/ai_settings_providers.dart';
import '../../settings_routes.dart';
import '../../state/ai_prompt_editor.dart';
import '../../state/ai_prompt_editor_guard.dart';
import '../settings_scaffold.dart';
import 'ai_catalog_labels.dart';
import 'prompt_editor_dialogs.dart';
import 'prompt_editor_fields.dart';
import 'prompt_editor_footer.dart';
import 'prompt_editor_sections.dart';
import 'prompt_editor_text.dart';

/// Settings › AI chat › "Sửa prompt" / "Prompt mới": label, prompt text with
/// insert-variable chips, a preview with sample values and, for a saved
/// prompt, the delete block. Typing changes nothing until Lưu. Every way out
/// of an edited form asks "Bỏ thay đổi?" first: [Huỷ], the header arrow,
/// system Back, Esc, and (through the route's `onExit`) any jump the router
/// makes, such as a sidebar item.
class AiPromptEditorPage extends ConsumerStatefulWidget {
  /// [index] is the place in the stored list; null opens a new prompt.
  const AiPromptEditorPage({super.key, this.index});

  final int? index;

  @override
  ConsumerState<AiPromptEditorPage> createState() => _AiPromptEditorPageState();
}

class _AiPromptEditorPageState extends ConsumerState<AiPromptEditorPage> {
  final _label = LimitedController(maxChars: promptLabelMaxChars);
  final _body = LimitedController(maxChars: promptBodyMaxChars);
  final _labelFocus = FocusNode();
  final _bodyFocus = FocusNode();
  late final PromptEditorGuard _guard;

  PromptEditorTarget? _target;
  bool _gone = false;
  bool _asking = false;

  /// A save, delete or leave is under way: a second tap does nothing.
  bool _busy = false;
  bool _popping = false;

  /// The user chose to leave (saved, deleted or discarded): nothing asks again.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _guard = ref.read(promptEditorGuardProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_target != null || _gone) return;
    final target = _resolve(AppLocalizations.of(context));
    if (target == null) {
      // A stale link: the prompt is not in the list any more.
      _gone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(SettingsPaths.ai);
      });
      return;
    }
    _target = target;
    _label.text = target.label;
    _body.text = target.body;
    _label.addListener(_sync);
    _body.addListener(_sync);
    _guard.attach(_confirmLeave);
  }

  @override
  void dispose() {
    _guard.detach(_confirmLeave);
    _label.dispose();
    _body.dispose();
    _labelFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  /// The prompt at [AiPromptEditorPage.index] with the texts the list shows
  /// (a builtin's come from l10n); null when there is no such prompt.
  PromptEditorTarget? _resolve(AppLocalizations l10n) {
    final i = widget.index;
    if (i == null) return const PromptEditorTarget();
    final list = ref.read(aiPromptsProvider);
    if (i < 0 || i >= list.length || list[i].isUnknown) return null;
    final t = list[i];
    final key = t.key;
    final builtin = key == null ? null : builtinTemplateText(l10n, key);
    final label = t.label ?? builtin?.label;
    final body = t.body ?? builtin?.body;
    if (label == null || body == null) return null;
    return PromptEditorTarget(index: i, key: key, label: label, body: body);
  }

  PromptEditor get _editor => ref.read(promptEditorProvider(_target!).notifier);

  void _sync() => _editor
    ..setLabel(_label.text)
    ..setBody(_body.text);

  /// Asks "Bỏ thay đổi?"; true = discard. One dialog at a time.
  Future<bool> _askDiscard() async {
    if (_asking) return false;
    _asking = true;
    final discard = await showPromptDiscardDialog(
      context,
      AppLocalizations.of(context),
    );
    _asking = false;
    return discard;
  }

  /// The router asks before it leaves (a sidebar item, Back, a branch
  /// switch). On "Bỏ" the form goes back to what it opened with: a page kept
  /// alive behind another branch comes back clean and asks again once edited.
  Future<bool> _confirmLeave() async {
    final target = _target;
    if (target == null || _leaving) return true;
    if (!ref.read(promptEditorProvider(target)).dirty) return true;
    final discard = await _askDiscard();
    if (discard && mounted) {
      _label.text = target.label;
      _body.text = target.body;
    }
    return discard;
  }

  /// The page's own exits (Huỷ, ←, Back, Esc): ask when edited, then leave.
  Future<void> _close() async {
    if (_busy) return;
    setState(() => _busy = true);
    final dirty = ref.read(promptEditorProvider(_target!)).dirty;
    final leave = !dirty || await _askDiscard();
    if (!mounted) return;
    if (leave) {
      _leave();
    } else {
      setState(() => _busy = false);
    }
  }

  /// Goes back to the AI settings page (the page was opened from it; a direct
  /// link has no history). Once.
  void _leave() {
    if (_popping) return;
    _popping = true;
    setState(() {
      _leaving = true;
      _busy = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(SettingsPaths.ai);
      }
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final label = _label.text.trim();
    final saved = await _editor.save();
    if (!mounted) return;
    if (!saved) {
      setState(() => _busy = false);
      return;
    }
    _leave();
    if (messenger != null && messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.aiSetEdSaved(label));
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final target = _target!;
    final label = _label.text.trim();
    final confirmed = await confirmAction(
      context,
      title: l10n.aiSetEdDeleteTitle(label),
      message: target.isBuiltin
          ? l10n.aiSetEdDeleteBodyBuiltin(l10n.aiSetPromptRestore)
          : l10n.aiSetEdDeleteBodyCustom,
      confirmLabel: l10n.aiSetEdDeleteConfirm,
      destructive: true,
    );
    final deleted = confirmed && mounted && await _editor.delete();
    if (!mounted) return;
    if (!deleted) {
      setState(() => _busy = false);
      return;
    }
    _leave();
    if (messenger != null && messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.aiSetEdDeleted(label));
    }
  }

  void _insert(AiVariable variable) {
    _body.insertAtCaret(variableToken(variable));
    _bodyFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    if (target == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(promptEditorProvider(target));
    final analysis = ref.watch(promptEditorAnalysisProvider(target));
    final line = promptLine(
      l10n,
      analysis,
      bypass: ref.watch(aiVarBypassProvider),
    );
    return PopScope(
      canPop: !state.dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              Expanded(
                child: SettingsScaffold(
                  title: target.isNew
                      ? l10n.aiSetEdTitleNew
                      : l10n.aiSetEdTitleEdit,
                  parentPath: SettingsPaths.ai,
                  headerBuilder: (context, _) => PageHeader(
                    title: target.isNew
                        ? l10n.aiSetEdTitleNew
                        : l10n.aiSetEdTitleEdit,
                    onBack: _close,
                    backTooltip: l10n.tooltipBack,
                  ),
                  children: promptEditorSections(
                    context,
                    label: _label,
                    labelFocus: _labelFocus,
                    body: _body,
                    bodyFocus: _bodyFocus,
                    analysis: analysis,
                    line: line,
                    onInsert: _insert,
                    builtin: target.isBuiltin,
                    onDelete: target.isNew ? null : _delete,
                  ),
                ),
              ),
              PromptEditorFooter(
                onCancel: _close,
                onSave: state.canSave(analysis) && !_busy ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
