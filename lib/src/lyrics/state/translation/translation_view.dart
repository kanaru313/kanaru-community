import 'package:flutter/foundation.dart' show mapEquals;

import '../../data/translation/translation_cache_store.dart';
import '../../data/translation/translation_job_types.dart';
import '../../domain/translation/translation_failure.dart';
import '../../domain/translation/translation_language.dart';

/// What the lyrics views show about the translation of one track.
class TranslationView {
  const TranslationView({
    required this.status,
    this.map = const {},
    this.sourceLang,
    this.installId,
    this.settingsDiffer = false,
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

  @override
  bool operator ==(Object other) =>
      other is TranslationView &&
      other.status == status &&
      mapEquals(other.map, map) &&
      other.sourceLang == sourceLang &&
      other.installId == installId &&
      other.settingsDiffer == settingsDiffer;

  @override
  int get hashCode =>
      Object.hash(status, map.length, sourceLang, installId, settingsDiffer);
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
);
