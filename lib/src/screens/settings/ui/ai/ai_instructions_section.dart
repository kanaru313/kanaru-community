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
/// [instructionsMaxChars] characters (the field stops typing and paste there;
/// a cluster that would still go over is cut).
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    // The setting counts code points; the field counts characters.
    var value = text;
    if (value.runes.length > instructionsMaxChars) {
      value = String.fromCharCodes(value.runes.take(instructionsMaxChars));
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _save(value);
  }

  Future<void> _save(String value) async {
    try {
      await ref.read(aiInstructionsProvider.notifier).set(value);
    } on Object catch (e, st) {
      // The settings store reports a failing write on the page banner.
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
          child: KTextFieldRow(
            controller: _controller,
            hint: l10n.aiSetInstructionsPlaceholder,
            rows: 4,
            maxLength: instructionsMaxChars,
            onChanged: _changed,
          ),
        ),
      ],
    );
  }
}
