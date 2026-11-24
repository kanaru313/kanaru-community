import 'package:flutter/foundation.dart' show mapEquals;

import '../../data/translation/translation_cache_store.dart';
import '../../data/translation/translation_job_types.dart';
import '../../domain/translation/translation_status.dart';
import '../../domain/translation/translation_language.dart';

/// What the lyrics views show about the translation of one track.
class TranslationView {
  const TranslationView({
    required this.status,
    this.map = const {},
    this.sourceLang,
    this.installId,
    this.settingsDiffer = false,
    this.settingsJson,
    this.linesDone = 0,
    this.linesTotal = 0,
  });

  /// Nothing asked, nothing to show.
  static const idle = TranslationView(status: TranslationStatus.idle());

  final TranslationStatus status;

  /// Source line (trimmed) to translation; empty while there is none.
  final Map<String, String> map;

  /// The language the plugin saw, null when unknown.
  final String? sourceLang;

  /// The plugin whose translation [map] is (the chosen service, or another
  /// plugin's saved one for [StatusOther]).
  final String? installId;

  /// The saved translation was made with other plugin settings (version,
  /// model, style, note) than the plugin has now: the modal offers
  /// "Dịch lại"; nothing re-runs by itself.
  final bool settingsDiffer;

  /// `{pluginVersion, model, style, instructionHash}` the shown [map] was
  /// made with; null when there is none.
  final String? settingsJson;

  /// Unique lines translated of the lines to translate, while a run goes and
  /// after a run that stopped half way (0 / 0 when unknown). With
  /// [linesTotal] it is the "dịch dở n/m dòng" of a failed run.
  final int linesDone;
  final int linesTotal;

  @override
  bool operator ==(Object other) =>
      other is TranslationView &&
      other.status == status &&
      mapEquals(other.map, map) &&
      other.sourceLang == sourceLang &&
      other.installId == installId &&
      other.settingsDiffer == settingsDiffer &&
      other.settingsJson == settingsJson &&
      other.linesDone == linesDone &&
      other.linesTotal == linesTotal;

  @override
  int get hashCode => Object.hash(
    status,
    map.length,
    sourceLang,
    installId,
    settingsDiffer,
    linesDone,
    linesTotal,
  );
}

/// The view of a complete saved translation made by [service]. Lyrics that
/// already are in [target] read as `same`.
TranslationView savedTranslationView(
  TranslationCacheRow row,
  String service,
  String target, {
  required bool differ,
}) {
  final source = row.sourceLang;
  final same = source != null && sameLanguage(source, target);
  return TranslationView(
    status: same
        ? TranslationStatus.same(target)
        : const TranslationStatus.ready(),
    map: row.lines,
    sourceLang: source,
    installId: service,
    settingsDiffer: differ,
    settingsJson: row.settingsJson,
  );
}

/// Whether [status] belongs to a forced re-run ("Dịch lại").
bool isForcedJob(JobStatus? status) => switch (status) {
  JobRunning(:final forced) => forced,
  JobFailed(:final forced) => forced,
  null => false,
};

/// The view of a job's [status] (null: asked, not started). [base] is the
/// translation on screen that a forced run keeps until the new one is
/// complete; any other run shows nothing until then.
TranslationView jobTranslationView(
  JobStatus? status, {
  TranslationView? base,
}) => TranslationView(
  status: switch (status) {
    null => const TranslationStatus.loading(0, 0),
    JobRunning(:final done, :final total, :final forced) =>
      TranslationStatus.loading(done, total, background: forced),
    JobFailed(:final failure) => TranslationStatus.failed(failure),
  },
  map: base?.map ?? const {},
  sourceLang: base?.sourceLang,
  installId: base?.installId,
  settingsDiffer: base?.settingsDiffer ?? false,
  settingsJson: base?.settingsJson,
  linesDone: status is JobRunning ? status.linesDone : 0,
  linesTotal: status is JobRunning ? status.linesTotal : 0,
);

/// The view of a failed run that left [row] half done (its chunks are saved,
/// `complete` is false): the translated lines stay on screen and the counts
/// say how many are there.
TranslationView partialFailureView(
  TranslationView failed,
  TranslationCacheRow row,
  int linesTotal,
) => TranslationView(
  status: failed.status,
  map: row.lines,
  sourceLang: row.sourceLang,
  installId: row.key.installId,
  settingsJson: row.settingsJson,
  linesDone: row.lines.length,
  linesTotal: linesTotal,
);
