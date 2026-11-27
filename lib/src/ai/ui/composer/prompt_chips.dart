import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/chat_session.dart';
import '../../state/chat_view/composer_draft.dart';
import '../../state/chat_view/composer_inputs.dart';
import '../../state/chat_view/composer_send.dart';
import '../../state/chat_view/composer_view.dart';
import '../../state/chat_view/prompt_apply.dart';
import 'prompt_text.dart';

/// The saved prompts: a column of outlined buttons under the greeting of an
/// empty chat ([large]), chips small and scrolling sideways above the composer once the chat
/// has messages. They lock with the pickers (the lock table). A prompt whose
/// variable has no data now is dimmed with its reason.
class PromptChips extends ConsumerWidget {
  const PromptChips({super.key, required this.large});

  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(
      composerViewProvider.select((v) => v.promptChipsEnabled),
    );
    final data = ref.watch(chatPromptDataProvider);
    final prompts = <(ResolvedPrompt, PromptLack?)>[
      for (final t in ref.watch(composerSettingsProvider).enabledPrompts)
        if (resolvePrompt(l10n, t) case final p?) (p, promptLack(p.body, data)),
    ];
    if (prompts.isEmpty) return const SizedBox.shrink();

    String? reason(PromptLack? lack) => switch (lack) {
      PromptLack.noPlaying => l10n.aiChatPromptNoPlaying,
      PromptLack.emptyQueue => l10n.aiChatPromptEmptyQueue,
      null => null,
    };

    Widget chip((ResolvedPrompt, PromptLack?) entry) {
      final (prompt, lack) = entry;
      final why = reason(lack);
      if (large) {
        return KPromptButton(
          label: prompt.label,
          reason: why,
          enabled: enabled && lack == null,
          onTap: () => usePrompt(ref, prompt.body),
        );
      }
      return KChip(
        label: Text(prompt.label),
        dense: true,
        outlined: true,
        enabled: enabled && lack == null,
        semanticLabel: why == null ? null : '${prompt.label}. $why',
        onTap: () => usePrompt(ref, prompt.body),
      );
    }

    return Semantics(
      container: true,
      label: l10n.aiChatPromptsLabel,
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: KSpace.x2,
              children: [for (final p in prompts) chip(p)],
            )
          : KChipLine(children: [for (final p in prompts) chip(p)]),
    );
  }
}

/// Tap on a prompt chip: sends it when the field is empty and it has no
/// blank, else fills the field (see [applyPrompt]). A send that does not go
/// through leaves the prompt in the field, so nothing is lost.
Future<void> usePrompt(WidgetRef ref, String body) async {
  final draft = ref.read(composerDraftProvider.notifier);
  final focus = ref.read(composerFocusRequestProvider.notifier);
  final session = ref.read(chatSessionProvider.notifier);
  final notice = ref.read(composerSendNoticeProvider.notifier);
  switch (applyPrompt(body, ref.read(composerDraftProvider))) {
    case PromptFill(:final value):
      draft.set(value);
      focus.request();
    case PromptSendNow(:final text):
      final result = await session.send(text);
      if (result is! SendSent) {
        // Write the field first: a change of its text ends the send note, so
        // the note is recorded after it.
        draft.set(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        focus.request();
      }
      recordSendResult(notice, result);
  }
}
