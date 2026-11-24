import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../../database/app_database.dart';
import '../../../database/tables.dart';

final _log = Logger('translation_cache');

/// Key of one cached translation: the lyrics text, the plugin and the target
/// language.
typedef TranslationKey = ({
  String contentHash,
  String installId,
  String targetLang,
});

/// What a write to the translation cache did.
enum TranslationWrite {
  /// The row is written.
  stored,

  /// Nothing was written: there is no row to complete.
  missing,

  /// Nothing was written: the lines would pass the row size cap.
  tooLarge,

  /// The database refused the write (logged, type only).
  failed,
}

/// One cached translation, decoded. Not the drift row, so `state` never sees
/// the database types.
class TranslationCacheRow {
  const TranslationCacheRow({
    required this.key,
    required this.sourceLang,
    required this.lines,
    required this.settingsJson,
    required this.complete,
    required this.createdAt,
  });

  final TranslationKey key;

  /// Dominant source language, null when unknown.
  final String? sourceLang;

  /// Source line to translated line.
  final Map<String, String> lines;

  /// `{pluginVersion, model, style, instructionHash}` of the run.
  final String settingsJson;

  /// False while chunks are still arriving: such a row is never reused as a
  /// finished translation.
  final bool complete;
  final int createdAt;
}

TranslationCacheRow _fromRow(LyricsTranslationRow r) => TranslationCacheRow(
  key: (
    contentHash: r.contentHash,
    installId: r.installId,
    targetLang: r.targetLang,
  ),
  sourceLang: r.sourceLang,
  lines: _decodeLines(r.linesJson),
  settingsJson: r.settingsJson,
  complete: r.complete,
  createdAt: r.createdAt,
);

/// A damaged `lines_json` reads as no lines, never as an error: the cache is
/// safe to drop and the engine translates again.
Map<String, String> _decodeLines(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  } on FormatException {
    return const {};
  }
}

/// The translation cache. Safe to drop; no foreign key.
class TranslationCacheStore {
  TranslationCacheStore(this._db);

  final AppDatabase _db;

  $LyricsTranslationsTable get _t => _db.lyricsTranslations;

  Expression<bool> _isKey(TranslationKey key) =>
      _t.contentHash.equals(key.contentHash) &
      _t.installId.equals(key.installId) &
      _t.targetLang.equals(key.targetLang);

  /// The row of [key], complete or not; null when there is none. A database
  /// error is logged and rethrown for the caller to show.
  Future<TranslationCacheRow?> lookup(TranslationKey key) async {
    try {
      final row = await (_db.select(
        _t,
      )..where((t) => _isKey(key))).getSingleOrNull();
      return row == null ? null : _fromRow(row);
    } on Object catch (e) {
      _log.warning('Translation cache read failed: ${e.runtimeType}');
      rethrow;
    }
  }

  /// The newest complete translation of [contentHash] into [targetLang] made
  /// by another plugin than [excluding] that is still installed and is a
  /// translate plugin, or null. An incomplete row, a removed plugin and a
  /// plugin of another kind never count.
  Future<TranslationCacheRow?> newestOther(
    String contentHash,
    String targetLang, {
    required String excluding,
  }) async {
    try {
      final query =
          _db.select(_t).join([
              innerJoin(
                _db.plugins,
                _db.plugins.installId.equalsExp(_t.installId),
              ),
            ])
            ..where(
              _t.contentHash.equals(contentHash) &
                  _t.targetLang.equals(targetLang) &
                  _t.installId.equals(excluding).not() &
                  _t.complete.equals(true) &
                  _db.plugins.removedAt.isNull() &
                  _db.plugins.kind.isIn(const ['translate', 'ai-translate']),
            )
            ..orderBy([
              OrderingTerm.desc(_t.createdAt),
              OrderingTerm.asc(_t.installId),
            ])
            ..limit(1);
      final rows = await query.get();
      return rows.isEmpty ? null : _fromRow(rows.single.readTable(_t));
    } on Object catch (e) {
      _log.warning('Translation cache read failed: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Merges [lines] into the row of [key] (created when missing) and marks
  /// it incomplete, in one transaction. Earlier chunks stay.
  Future<TranslationWrite> mergeChunk(
    TranslationKey key,
    Map<String, String> lines, {
    required String settingsJson,
    required int now,
  }) async {
    try {
      return await _db.transaction(() async {
        final existing = await (_db.select(
          _t,
        )..where((t) => _isKey(key))).getSingleOrNull();
        final merged = {
          if (existing != null) ..._decodeLines(existing.linesJson),
          ...lines,
        };
        final json = jsonEncode(merged);
        if (json.length > TranslationLimits.maxLinesJsonLength) {
          return TranslationWrite.tooLarge;
        }
        await _db
            .into(_t)
            .insertOnConflictUpdate(
              LyricsTranslationsCompanion.insert(
                contentHash: key.contentHash,
                installId: key.installId,
                targetLang: key.targetLang,
                sourceLang: Value(existing?.sourceLang),
                linesJson: json,
                // The first chunk's settings stay: a row whose chunks span a
                // settings save reads as differing, so "Dịch lại" is offered.
                settingsJson: existing?.settingsJson ?? settingsJson,
                complete: const Value(false),
                createdAt: existing?.createdAt ?? now,
              ),
            );
        return TranslationWrite.stored;
      });
    } on Object catch (e) {
      _log.warning('Translation cache write failed: ${e.runtimeType}');
      return TranslationWrite.failed;
    }
  }

  /// Marks the row of [key] complete and records the source language the
  /// plugin saw ([TranslationWrite.missing] when there is no row).
  Future<TranslationWrite> markComplete(
    TranslationKey key, {
    String? sourceLang,
  }) async {
    try {
      final n = await (_db.update(_t)..where((t) => _isKey(key))).write(
        LyricsTranslationsCompanion(
          complete: const Value(true),
          sourceLang: sourceLang == null
              ? const Value.absent()
              : Value(sourceLang),
        ),
      );
      return n == 0 ? TranslationWrite.missing : TranslationWrite.stored;
    } on Object catch (e) {
      _log.warning('Translation cache write failed: ${e.runtimeType}');
      return TranslationWrite.failed;
    }
  }

  /// Replaces the whole row of [row]'s key (a forced re-run that finished).
  Future<TranslationWrite> replace(TranslationCacheRow row) async {
    final json = jsonEncode(row.lines);
    if (json.length > TranslationLimits.maxLinesJsonLength) {
      return TranslationWrite.tooLarge;
    }
    try {
      await _db
          .into(_t)
          .insertOnConflictUpdate(
            LyricsTranslationsCompanion.insert(
              contentHash: row.key.contentHash,
              installId: row.key.installId,
              targetLang: row.key.targetLang,
              sourceLang: Value(row.sourceLang),
              linesJson: json,
              settingsJson: row.settingsJson,
              complete: Value(row.complete),
              createdAt: row.createdAt,
            ),
          );
      return TranslationWrite.stored;
    } on Object catch (e) {
      _log.warning('Translation cache write failed: ${e.runtimeType}');
      return TranslationWrite.failed;
    }
  }

  /// The row of [key], re-emitted on change; null while there is none. A
  /// database error arrives as a stream error (logged here, type only).
  Stream<TranslationCacheRow?> watch(TranslationKey key) =>
      (_db.select(_t)..where((t) => _isKey(key)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _fromRow(r))
          .transform(
            StreamTransformer<
              TranslationCacheRow?,
              TranslationCacheRow?
            >.fromHandlers(
              handleError: (e, st, sink) {
                _log.warning(
                  'Translation cache watch failed: ${e.runtimeType}',
                );
                sink.addError(e, st);
              },
            ),
          );
}
