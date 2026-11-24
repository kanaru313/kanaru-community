import 'dart:async';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../../database/app_database.dart';
import '../../../database/tables.dart';
import '../../../media/domain/track_id.dart';
import '../../../plugins/domain/package/translate_spec.dart'
    show translationLanguageCodes;

final _log = Logger('translation_prefs');

/// The per-track translation language ("Dịch sang…" for this song only).
/// No row = the global target applies.
class TranslationPrefsStore {
  TranslationPrefsStore(this._db);

  final AppDatabase _db;

  /// The language picked for [id], null when none; re-emitted on change. A
  /// database error arrives as a stream error (logged, type only).
  Stream<String?> watch(TrackId id) =>
      (_db.select(_db.trackTranslationPrefs)
            ..where((t) => t.trackId.equals(id.value)))
          .watchSingleOrNull()
          .map((r) => r?.targetLang)
          .transform(
            StreamTransformer<String?, String?>.fromHandlers(
              handleError: (e, st, sink) {
                _log.warning('Translation pref watch failed: ${e.runtimeType}');
                sink.addError(e, st);
              },
            ),
          );

  /// Sets the language of [id]; null removes the choice (the row goes).
  /// Throws [ArgumentError] for a code outside [translationLanguageCodes].
  /// Returns false when the database refused (logged), e.g. the track was
  /// collected meanwhile.
  Future<bool> setTarget(TrackId id, String? lang, {required int now}) async {
    if (lang != null && !translationLanguageCodes.contains(lang)) {
      throw ArgumentError.value(lang, 'lang', 'not a translation language');
    }
    try {
      if (lang == null) {
        await (_db.delete(
          _db.trackTranslationPrefs,
        )..where((t) => t.trackId.equals(id.value))).go();
      } else {
        await _db
            .into(_db.trackTranslationPrefs)
            .insertOnConflictUpdate(
              TrackTranslationPrefsCompanion.insert(
                trackId: Value(id.value),
                targetLang: Value(lang),
                updatedAt: now,
              ),
            );
      }
      return true;
    } on Object catch (e) {
      _log.warning('Translation pref write failed: ${e.runtimeType}');
      return false;
    }
  }
}
