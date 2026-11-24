import 'translation_failure.dart';

/// What the lyrics screen shows about the translation of the playing song.
sealed class TranslationStatus {
  const TranslationStatus();

  /// Nothing asked, nothing running.
  const factory TranslationStatus.idle() = StatusIdle;

  /// [done] of [total] chunks finished; [background] when not on screen.
  const factory TranslationStatus.loading(
    int done,
    int total, {
    bool background,
  }) = StatusLoading;

  /// Translation is available.
  const factory TranslationStatus.ready() = StatusReady;

  /// The saved translation was made by another plugin ([installId]).
  const factory TranslationStatus.other(String installId) = StatusOther;

  /// The lyrics already are in [lang], the target.
  const factory TranslationStatus.same(String lang) = StatusSame;

  /// The last attempt failed.
  const factory TranslationStatus.failed(TranslationFailure failure) =
      StatusFailed;
}

final class StatusIdle extends TranslationStatus {
  const StatusIdle();

  @override
  bool operator ==(Object other) => other is StatusIdle;

  @override
  int get hashCode => (StatusIdle).hashCode;
}

final class StatusLoading extends TranslationStatus {
  const StatusLoading(this.done, this.total, {this.background = false});

  final int done;
  final int total;
  final bool background;

  @override
  bool operator ==(Object other) =>
      other is StatusLoading &&
      other.done == done &&
      other.total == total &&
      other.background == background;

  @override
  int get hashCode => Object.hash(done, total, background);
}

final class StatusReady extends TranslationStatus {
  const StatusReady();

  @override
  bool operator ==(Object other) => other is StatusReady;

  @override
  int get hashCode => (StatusReady).hashCode;
}

final class StatusOther extends TranslationStatus {
  const StatusOther(this.installId);

  final String installId;

  @override
  bool operator ==(Object other) =>
      other is StatusOther && other.installId == installId;

  @override
  int get hashCode => installId.hashCode;
}

final class StatusSame extends TranslationStatus {
  const StatusSame(this.lang);

  final String lang;

  @override
  bool operator ==(Object other) => other is StatusSame && other.lang == lang;

  @override
  int get hashCode => lang.hashCode;
}

final class StatusFailed extends TranslationStatus {
  const StatusFailed(this.failure);

  final TranslationFailure failure;

  @override
  bool operator ==(Object other) =>
      other is StatusFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
