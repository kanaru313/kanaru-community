import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../../plugins/data/store/plugin_config_store.dart' show ConfigWrite;
import '../../../plugins/state/plugin_actions_provider.dart';
import '../lyrics_choice_commands.dart' show lyricsClockProvider;
import 'translation_providers.dart';
import 'translation_settings.dart';

/// Everything the translation UI changes. Settings go through their
/// notifiers; model, style and note are the plugin's own stored settings,
/// written through the plugin store's config writes (the plugin reads them
/// itself on every run; nothing is sent per run).
class TranslationCommands {
  TranslationCommands(this._ref);

  final Ref _ref;

  /// Turns translation on or off for every song.
  Future<void> toggle() => _ref
      .read(translationOnProvider.notifier)
      .set(!_ref.read(translationOnProvider));

  /// The chosen service (an install id), or null for none.
  Future<void> setService(String? installId) =>
      _ref.read(translationServiceProvider.notifier).set(installId);

  Future<void> setDisplay(TranslationDisplay display) =>
      _ref.read(translationDisplayProvider.notifier).set(display);

  /// The language of one song; null goes back to the default. Throws
  /// [ArgumentError] for a code the app does not know. False when the
  /// database refused.
  Future<bool> setTarget(TrackId id, String? lang) => _ref
      .read(translationPrefsStoreProvider)
      .setTarget(id, lang, now: _ref.read(lyricsClockProvider)());

  /// "Dịch lại" for [id]; the view of that track must be watched.
  void retranslate(TrackId id) =>
      _ref.read(trackTranslationProvider(id).notifier).retranslate();

  /// "Thử lại" after a failure.
  void retry(TrackId id) =>
      _ref.read(trackTranslationProvider(id).notifier).retry();

  /// Stops a running "Dịch lại".
  void cancelRetranslate(TrackId id) =>
      _ref.read(trackTranslationProvider(id).notifier).cancelRetranslate();

  /// The AI model of [installId] (all songs). [ConfigWrite.unknownKey] when
  /// the plugin does not declare a `model` setting.
  Future<ConfigWrite> setModel(String installId, String? value) =>
      _write(installId, 'model', value);

  Future<ConfigWrite> setStyle(String installId, String? value) =>
      _write(installId, 'style', value);

  /// "Lời dặn thêm" for all songs: the plugin's `customInstruction`.
  Future<ConfigWrite> setNote(String installId, String? value) =>
      _write(installId, 'customInstruction', value);

  Future<ConfigWrite> _write(String installId, String key, String? value) =>
      _ref
          .read(pluginActionsProvider)
          .configWrites
          .setValue(installId, key, value);
}

final translationCommandsProvider = Provider<TranslationCommands>(
  TranslationCommands.new,
);
