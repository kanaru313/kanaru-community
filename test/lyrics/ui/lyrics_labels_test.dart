import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_summary.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_labels.dart';

void main() {
  final en = AppLocalizationsEn();

  test('every summary has a full label, only loading is empty', () {
    for (final summary in LyricsSummary.values) {
      final label = lyricsSummaryLabel(en, summary);
      expect(
        label.isEmpty,
        summary == LyricsSummary.loading,
        reason: '$summary',
      );
    }
  });

  test('the Vietnamese labels of the spec', () {
    final vi = AppLocalizationsVi();
    expect(
      lyricsSummaryLabel(vi, LyricsSummary.tagSynced),
      'Lời trong tag · Đồng bộ',
    );
    expect(lyricsSummaryLabel(vi, LyricsSummary.lrcPlain), 'Tệp .lrc · Thường');
    expect(lyricsSummaryLabel(vi, LyricsSummary.off), 'Tắt lời');
    expect(lyricsSummaryLabel(vi, LyricsSummary.none), 'Không có lời');
    expect(
      lyricsSummaryLabel(vi, LyricsSummary.lrcSynced, short: true),
      'Tệp .lrc',
    );
    expect(
      lyricsSummaryLabel(vi, LyricsSummary.tagPlain, short: true),
      'Trong tag',
    );
  });

  test('short labels name the source and say nothing when there is none', () {
    expect(lyricsSummaryLabel(en, LyricsSummary.off, short: true), 'Off');
    for (final summary in [
      LyricsSummary.none,
      LyricsSummary.unavailable,
      LyricsSummary.loading,
    ]) {
      expect(lyricsSummaryLabel(en, summary, short: true), isEmpty);
    }
  });

  test('a track with no local file reads like one with no lyrics', () {
    expect(
      lyricsSummaryLabel(en, LyricsSummary.unavailable),
      lyricsSummaryLabel(en, LyricsSummary.none),
    );
  });
}
