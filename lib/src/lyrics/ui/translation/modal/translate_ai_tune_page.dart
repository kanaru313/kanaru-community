import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../plugins/data/store/plugin_config_store.dart'
    show ConfigWrite;
import '../../../../plugins/domain/config/config_field.dart' show SelectField;
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_providers.dart';
import '../../../state/translation/translation_tune_provider.dart';
import 'translate_frame.dart';
import 'translate_page_parts.dart';
import 'translate_retranslate.dart';
import 'translate_scope_segmented.dart';
import 'translate_tune_field.dart';
import 'translate_tune_footer.dart';
import 'translate_tune_note.dart';
import 'translate_tune_select.dart';

/// "Tinh chỉnh AI" of the AI plugin [installId]: Model and Phong cách (each
/// opens a select), "Lời dặn thêm" for every song, and the footer: [Để sau]
/// [Dịch lại] when the settings differ from the translation shown, else
/// [Xong]. Everything is the plugin's own stored setting; a write the store
/// refuses shows its error line.
class TranslateAiTunePage extends ConsumerStatefulWidget {
  const TranslateAiTunePage({
    super.key,
    required this.control,
    required this.installId,
  });

  final TranslateModalControl control;
  final String installId;

  @override
  ConsumerState<TranslateAiTunePage> createState() =>
      _TranslateAiTunePageState();
}

class _TranslateAiTunePageState extends ConsumerState<TranslateAiTunePage> {
  final _note = GlobalKey<TranslateNoteFieldState>();
  final Map<String, String> _errors = {};

  /// Runs [write] and keeps (or clears) the error line of [key].
  Future<void> _write(String key, Future<ConfigWrite> Function() write) async {
    final l10n = AppLocalizations.of(context);
    ConfigWrite result;
    try {
      result = await write();
    } on Object {
      // The store never throws by contract; a failure is shown like a refusal.
      result = ConfigWrite.failed;
    }
    if (!mounted) return;
    setState(() {
      if (result == ConfigWrite.written) {
        _errors.remove(key);
      } else {
        _errors[key] = configWriteMessage(l10n, result);
      }
    });
  }

  Future<void> _open(
    String key,
    String title,
    SelectField field,
    String? selected,
  ) {
    final commands = ref.read(translationCommandsProvider);
    return showTuneSelect(
      context,
      title: title,
      field: field,
      selected: selected,
      onPick: (value) => _write(
        key,
        () => key == 'model'
            ? commands.setModel(widget.installId, value)
            : commands.setStyle(widget.installId, value),
      ),
    );
  }

  Future<void> _done({required bool translate}) async {
    final navigator = Navigator.of(context);
    final saved = await _note.currentState?.flush() ?? true;
    // A refused note stays on screen with its error line.
    if (!mounted || !saved) return;
    if (translate) retranslateInBackground(context, widget.control);
    // Back to the modal's main page, which shows the run's status line.
    if (navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tune = ref.watch(translateTuneProvider(widget.installId)).value;
    final differ = ref.watch(
      trackTranslationProvider(widget.control.trackId)
          .select((v) => v.settingsDiffer),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslatePageHeader(
          title: l10n.lyricsTranslateTuneTitle,
          onClose: () => Navigator.of(context).pop(),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TranslateScopeSegmented(),
                if (tune?.model case final model?)
                  TranslateTuneField(
                    sectionTitle: l10n.lyricsTranslateModelTitle,
                    field: model,
                    value: tune!.modelValue,
                    error: _errors['model'],
                    onOpen: () => _open(
                      'model',
                      l10n.lyricsTranslateModelTitle,
                      model,
                      tune.modelValue,
                    ),
                  ),
                if (tune?.style case final style?)
                  TranslateTuneField(
                    sectionTitle: l10n.lyricsTranslateStyleTitle,
                    field: style,
                    value: tune!.styleValue,
                    error: _errors['style'],
                    onOpen: () => _open(
                      'style',
                      l10n.lyricsTranslateStylePickerTitle,
                      style,
                      tune.styleValue,
                    ),
                  ),
                if (tune != null && tune.hasNote)
                  TranslateNoteField(
                    key: _note,
                    installId: widget.installId,
                    pluginName: tune.pluginName,
                  ),
                const KGap(KSpace.x2),
              ],
            ),
          ),
        ),
        TranslateTuneFooter(
          differ: differ,
          onLater: () => _done(translate: false),
          onTranslate: () => _done(translate: true),
        ),
      ],
    );
  }
}
