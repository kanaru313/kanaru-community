import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/variables/variable_catalog.dart';
import '../../state/chat_view/composer_inputs.dart';
import 'composer_text_controller.dart';
import 'variable_list.dart';

/// The message field: painted `{{variables}}`, the `{{` list, and the keys.
///
/// Desktop: Enter sends, Shift+Enter starts a new line. Phone: Enter starts a
/// new line (the send button sends). While an input method composes text,
/// Enter and `{{` belong to it: nothing is sent and no list opens.
class ComposerField extends ConsumerStatefulWidget {
  const ComposerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.editable,
    required this.onSubmit,
    this.missing = const {},
  });

  final ComposerTextController controller;
  final FocusNode focusNode;

  /// False while the chat's plugin is gone: the field only shows its hint.
  final bool editable;

  /// Enter on the desktop shell; the caller decides whether a send happens.
  final VoidCallback onSubmit;

  /// Names of variables the last send could not fill.
  final Set<String> missing;

  @override
  ConsumerState<ComposerField> createState() => _ComposerFieldState();
}

class _ComposerFieldState extends ConsumerState<ComposerField> {
  static final _open = RegExp(r'\{\{([a-z_]*)$');

  /// What follows `{{` so far; null while no list is open.
  String? _query;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(ComposerField old) {
    super.didUpdateWidget(old);
    if (old.controller == widget.controller) return;
    old.controller.removeListener(_onChanged);
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  List<AiVariable> get _matches {
    final query = _query;
    if (query == null) return const [];
    return [
      for (final v in variableCatalog)
        // {{input}} is the prompts' blank, not something to insert by hand.
        if (v != AiVariable.input && v.name.startsWith(query)) v,
    ];
  }

  void _onChanged() {
    final value = widget.controller.value;
    String? query;
    if (!isComposing(value) &&
        value.selection.isValid &&
        value.selection.isCollapsed) {
      final before = value.text.substring(0, value.selection.baseOffset);
      query = _open.firstMatch(before)?[1];
    }
    if (query == _query) return;
    setState(() {
      _query = query;
      _selected = 0;
    });
  }

  void _choose(AiVariable variable) {
    final value = widget.controller.value;
    final cursor = value.selection.baseOffset;
    final match = _open.firstMatch(value.text.substring(0, cursor));
    if (match == null) return;
    // A `}}` already after the cursor is part of what is replaced.
    final end = value.text.startsWith('}}', cursor) ? cursor + 2 : cursor;
    final insert = '{{${variable.name}}}';
    widget.controller.value = TextEditingValue(
      text: value.text.replaceRange(match.start, end, insert),
      selection: TextSelection.collapsed(offset: match.start + insert.length),
    );
    widget.focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (isComposing(widget.controller.value)) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final matches = _matches;
    if (matches.isNotEmpty) {
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(() => _selected = (_selected + 1) % matches.length);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        setState(
          () => _selected = (_selected - 1 + matches.length) % matches.length,
        );
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.tab) {
        _choose(matches[_selected.clamp(0, matches.length - 1)]);
        return KeyEventResult.handled;
      }
    }
    if (_query != null && key == LogicalKeyboardKey.escape) {
      setState(() => _query = null);
      return KeyEventResult.handled;
    }
    final enter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (enter &&
        FormFactor.of(context) == FormFactor.desktop &&
        !HardwareKeyboard.instance.isShiftPressed) {
      widget.onSubmit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(composerSettingsProvider);
    widget.controller
      ..groupEnabled = settings.groupEnabled
      ..missing = widget.missing;
    final matches = _matches;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (matches.isNotEmpty) ...[
          VariableList(
            items: matches,
            selected: _selected.clamp(0, matches.length - 1),
            onChoose: _choose,
          ),
          const SizedBox(height: KSpace.x2),
        ],
        Focus(
          onKeyEvent: _onKey,
          child: Semantics(
            label: l10n.aiChatComposerLabel,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              readOnly: !widget.editable,
              minLines: 1,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration.collapsed(
                hintText: widget.editable
                    ? l10n.aiChatComposerHint
                    : l10n.aiChatComposerHintLocked,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
