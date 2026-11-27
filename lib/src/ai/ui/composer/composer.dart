import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/variables/variable_filler.dart';
import '../../state/chat_attachments.dart';
import '../../state/chat_session.dart';
import '../../state/chat_view/composer_draft.dart';
import '../../state/chat_view/composer_inputs.dart';
import '../../state/chat_view/composer_send.dart';
import '../../state/chat_view/composer_view.dart';
import '../../state/chat_view/prompt_apply.dart';
import '../composer_draft_binding.dart';
import 'composer_buttons.dart';
import 'composer_field.dart';
import 'composer_notice.dart';
import 'composer_text_controller.dart';
import 'context_chips.dart';
import 'plugin_picker.dart';
import 'prompt_chips.dart';

final _log = Logger('ai.composer');

/// The message box under the conversation: a note, the context chips, the
/// field and the button row. With [showPromptChips] (the chat has messages)
/// the saved prompts scroll above it as small chips.
///
/// Which controls work follows the turn state (the lock table in
/// `composerViewProvider`); the field is always editable unless the chat's
/// plugin is gone.
class Composer extends StatelessWidget {
  const Composer({super.key, this.showPromptChips = false});

  final bool showPromptChips;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x3,
        KSpace.x1,
        KSpace.x3,
        KSpace.x3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPromptChips) ...[
            const PromptChips(large: false),
            const SizedBox(height: KSpace.x2),
          ],
          ComposerDraftBinding(
            builder: (context, controller, focus) =>
                _ComposerBox(controller: controller, focusNode: focus),
          ),
        ],
      ),
    );
  }
}

class _ComposerBox extends ConsumerStatefulWidget {
  const _ComposerBox({required this.controller, required this.focusNode});

  final ComposerTextController controller;
  final FocusNode focusNode;

  @override
  ConsumerState<_ComposerBox> createState() => _ComposerBoxState();
}

class _ComposerBoxState extends ConsumerState<_ComposerBox> {
  late String _text = widget.controller.text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  /// A refused send's note describes the text it refused: editing ends it.
  void _onChanged() {
    final text = widget.controller.text;
    if (text == _text) return;
    _text = text;
    ref.read(composerSendNoticeProvider.notifier).clear();
  }

  Future<void> _send({bool shortVersion = false}) async {
    if (!ref.read(composerViewProvider).canSend) return;
    final text = widget.controller.text;
    final chips = ref.read(chatAttachmentsProvider).attached;
    if (text.trim().isEmpty && chips.isEmpty) return;
    // Taken before the await: the chat may leave the screen meanwhile (a panel
    // swap), and what was sent must leave the draft all the same.
    final draft = ref.read(composerDraftProvider.notifier);
    final notice = ref.read(composerSendNoticeProvider.notifier);
    final SendResult result;
    try {
      result = await sendFromComposer(
        session: ref.read(chatSessionProvider.notifier),
        notice: notice,
        text: text,
        shortVersion: shortVersion,
      );
    } on Object catch (e, s) {
      _log.warning('send failed: ${e.runtimeType}', e, s);
      // The full text can hold chat text or request details: never printed
      // in release (only the type is), kept for debug logs.
      _log.fine('send failed, detail: $e', e, s);
      notice.set(const NoticeSendFailed());
      return;
    }
    // Clear only what was sent: typing meanwhile stays.
    if (result is SendSent) draft.clearIfSent(text);
    // A blank of a prompt that was left in: point at it.
    if (mounted &&
        result is SendMissingData &&
        result.issues.any(
          (i) => i is VariableIssue && i.issue is FillLeftoverInput,
        )) {
      final selected = selectInputBlank(widget.controller.value);
      if (selected != null) {
        widget.controller.value = selected;
        widget.focusNode.requestFocus();
      }
    }
  }

  void _stop() {
    unawaited(
      ref.read(chatSessionProvider.notifier).stop().catchError((
        Object e,
        StackTrace s,
      ) {
        _log.warning('stop failed: ${e.runtimeType}', e, s);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final view = ref.watch(composerViewProvider);
    final notice = view.notice;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: KRadius.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x3,
          KSpace.x3,
          KSpace.x2,
          KSpace.x1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notice != null) ...[
              ComposerNoticeView(
                notice: notice,
                model: view.model,
                onPickPlugin: () => showPluginPicker(context, ref),
                // The button row opens it, anchored to the model button.
                onPickModel: () =>
                    ref.read(modelPickerRequestProvider.notifier).request(),
                onSendShort: () => _send(shortVersion: true),
              ),
              const SizedBox(height: KSpace.x2),
            ],
            if (view.fieldEditable) ...[
              ContextChips(struck: view.struckChips),
              const SizedBox(height: KSpace.x2),
            ],
            ComposerField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              editable: view.fieldEditable,
              missing: missingVariableNames(notice),
              onSubmit: _send,
            ),
            const SizedBox(height: KSpace.x1),
            ComposerButtons(view: view, onSend: _send, onStop: _stop),
          ],
        ),
      ),
    );
  }
}
