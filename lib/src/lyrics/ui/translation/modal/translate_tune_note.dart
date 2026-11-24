import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../plugins/data/store/plugin_config_store.dart'
    show ConfigWrite;
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_tune_provider.dart';
import 'translate_page_parts.dart';
import 'translate_tune_footer.dart' show configWriteMessage;

/// "Lời dặn thêm" of the AI plugin [installId]: one note for every song, the
/// plugin's own `customInstruction` setting. It saves when the field loses
/// focus, when the page asks ([TranslateNoteFieldState.flush]) and when the
/// page goes away with the note still typed in; a refused write shows its
/// error line under the field. Changes made elsewhere (the plugin's page)
/// show here while the user is not typing.
class TranslateNoteField extends ConsumerStatefulWidget {
  const TranslateNoteField({
    super.key,
    required this.installId,
    required this.pluginName,
  });

  final String installId;
  final String pluginName;

  @override
  ConsumerState<TranslateNoteField> createState() => TranslateNoteFieldState();
}

class TranslateNoteFieldState extends ConsumerState<TranslateNoteField> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  late final ProviderContainer _container = ProviderScope.containerOf(
    context,
    listen: false,
  );

  /// Typed in and not saved yet.
  bool _dirty = false;
  String? _error;

  String? get _value => _text.text.trim().isEmpty ? null : _text.text;

  @override
  void initState() {
    super.initState();
    _text.text =
        _container.read(translateTuneProvider(widget.installId)).value?.note ??
        '';
    _focus.addListener(() {
      if (!_focus.hasFocus) unawaited(flush());
    });
  }

  @override
  void dispose() {
    // Back or ✕ with the note still being typed: save it, nothing is lost.
    if (_dirty) {
      unawaited(
        _container
            .read(translationCommandsProvider)
            .setNote(widget.installId, _value),
      );
    }
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Saves the note when it was typed in. False when the store refused it
  /// (the error line is showing).
  Future<bool> flush() async {
    if (!_dirty) return _error == null;
    _dirty = false;
    final l10n = AppLocalizations.of(context);
    ConfigWrite result;
    try {
      result = await ref
          .read(translationCommandsProvider)
          .setNote(widget.installId, _value);
    } on Object {
      // The store does not throw by contract; shown like a refusal.
      result = ConfigWrite.failed;
    }
    if (!mounted) return result == ConfigWrite.written;
    setState(
      () => _error = result == ConfigWrite.written
          ? null
          : configWriteMessage(l10n, result),
    );
    return result == ConfigWrite.written;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(translateTuneProvider(widget.installId), (_, next) {
      final stored = next.value?.note;
      if (stored != null &&
          !_dirty &&
          !_focus.hasFocus &&
          stored != _text.text) {
        _text.text = stored;
      }
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslateSectionTitle(l10n.lyricsTranslateNoteTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x6),
          child: KTextFieldRow(
            controller: _text,
            focusNode: _focus,
            hint: l10n.lyricsTranslateNoteTitle,
            rows: 3,
            helper: l10n.lyricsTranslateNoteHelper(widget.pluginName),
            error: _error,
            onChanged: (_) => _dirty = true,
          ),
        ),
      ],
    );
  }
}
