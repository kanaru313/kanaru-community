import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/settings/prompt_template.dart';
import '../../../../ai/state/ai_settings_providers.dart';

final _log = Logger('settings.ai_instructions');

/// "Hướng dẫn chung": one box of standing instructions sent with every chat,
/// to every AI service. Typing saves at once; the text never goes over
/// [instructionsMaxChars] code points: the field stops typing at that many
/// characters, and an edit that would still pass the limit in code points
/// (an emoji with a skin tone is one character, two code points) is rejected:
/// the text and caret stay as they were, the end is never cut.
class AiInstructionsSection extends ConsumerStatefulWidget {
  const AiInstructionsSection({super.key});

  @override
  ConsumerState<AiInstructionsSection> createState() =>
      _AiInstructionsSectionState();
}

class _AiInstructionsSectionState extends ConsumerState<AiInstructionsSection> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(aiInstructionsProvider),
  );

  /// The last value within the limit (text and caret), put back when an edit
  /// would pass it.
  late TextEditingValue _last;

  @override
  void initState() {
    super.initState();
    _last = _controller.value;
    _controller.addListener(_remember);
  }

  void _remember() {
    final value = _controller.value;
    if (value.text.runes.length <= instructionsMaxChars) _last = value;
  }

  @override
  void dispose() {
    _controller.removeListener(_remember);
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    // The setting counts code points; the field counts characters.
    if (text.runes.length > instructionsMaxChars) {
      _controller.value = _last.copyWith(composing: TextRange.empty);
      return;
    }
    _save(text);
  }

  Future<void> _save(String value) async {
    try {
      await ref.read(aiInstructionsProvider.notifier).set(value);
    } on Object catch (e, st) {
      // Only a programmer error gets here (the store reports a failing write
      // itself); the field keeps the text.
      _log.warning('saving the instructions failed', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.aiSetInstructionsTitle;
    return SetupSection(
      title: Text(title),
      hint: l10n.aiSetInstructionsHint,
      hintTooltip: l10n.settingsSectionHintTooltip(title),
      hintTitle: title,
      children: [
        Padding(
          padding: const EdgeInsets.all(KSpace.x4),
          // The field has no visible label: the section title names it.
          child: Semantics(
            label: title,
            textField: true,
            child: KTextFieldRow(
              controller: _controller,
              hint: l10n.aiSetInstructionsPlaceholder,
              rows: 4,
              maxLength: instructionsMaxChars,
              onChanged: _changed,
            ),
          ),
        ),
      ],
    );
  }
}
