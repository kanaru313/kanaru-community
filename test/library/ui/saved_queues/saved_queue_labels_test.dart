import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_labels.dart';
import 'package:kanaru/src/media/domain/play_context.dart';

import 'support/fake_saved_queue_store.dart';

final _vi = AppLocalizationsVi();
final _en = AppLocalizationsEn();

int _at(int y, int m, int d, [int h = 21, int min = 17]) =>
    DateTime(y, m, d, h, min).millisecondsSinceEpoch;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
    await initializeDateFormatting('en');
  });

  group('savedQueueName', () {
    final today = DateTime(2026, 11, 21);

    test('today and yesterday are named, with the time', () {
      expect(savedQueueName(_vi, _at(2026, 11, 21), today), 'Hôm nay · 21:17');
      expect(
        savedQueueName(_vi, _at(2026, 11, 20, 8, 5), today),
        'Hôm qua · 8:05',
      );
      expect(savedQueueName(_en, _at(2026, 11, 21), today), 'Today · 21:17');
    });

    test(
      'just after midnight is still yesterday, a minute before it is not',
      () {
        expect(
          savedQueueName(_vi, _at(2026, 11, 20, 23, 59), today),
          startsWith('Hôm qua'),
        );
        expect(
          savedQueueName(_vi, _at(2026, 11, 21, 0, 0), today),
          startsWith('Hôm nay'),
        );
      },
    );

    test('up to 6 days back it is the weekday, then dd/MM', () {
      // 15 Nov 2026 is a Sunday, 6 days before the 21st.
      expect(savedQueueName(_en, _at(2026, 11, 15), today), 'Sunday · 21:17');
      expect(savedQueueName(_vi, _at(2026, 11, 15), today), contains('Chủ'));
      // 7 days back is a date.
      expect(savedQueueName(_vi, _at(2026, 11, 14), today), '14/11 · 21:17');
    });

    test('another year shows the year', () {
      expect(
        savedQueueName(_vi, _at(2025, 12, 31), today),
        '31/12/2025 · 21:17',
      );
      // Same month and day, other year: not read as this year's.
      expect(
        savedQueueName(_vi, _at(2025, 11, 21), today),
        '21/11/2025 · 21:17',
      );
    });

    test('a day is a calendar day: 25-hour days do not shift the label', () {
      // Whatever the zone of the machine, the same local dates give the same
      // label: yesterday is the previous calendar date, never "24 h ago".
      final t = DateTime(2026, 3, 29);
      expect(
        savedQueueName(
          _vi,
          DateTime(2026, 3, 28, 0, 30).millisecondsSinceEpoch,
          t,
        ),
        startsWith('Hôm qua'),
      );
      expect(
        savedQueueName(
          _vi,
          DateTime(2026, 3, 27, 23, 30).millisecondsSinceEpoch,
          t,
        ),
        startsWith('Thứ'),
      );
    });

    test('a saved time after today (a clock set back) reads as today', () {
      expect(
        savedQueueName(_vi, _at(2026, 11, 22), today),
        startsWith('Hôm nay'),
      );
    });
  });

  test('the export name carries the full date and never "today"', () {
    expect(
      savedQueueExportName(_vi, _at(2026, 11, 21)),
      'Hàng đợi 21/11/2026 21:17',
    );
    expect(
      savedQueueExportName(_en, _at(2026, 11, 21)),
      'Queue 21/11/2026 21:17',
    );
  });

  group('savedQueueStatsLine', () {
    final q = savedQueue(
      'q',
      savedAt: 0,
      ids: List.generate(24, (i) => i + 1),
    ).summary;

    test('songs and length; the missing count only above 0', () {
      expect(savedQueueStatsLine(_vi, q), '24 bài · 24 phút');
      expect(
        savedQueueStatsLine(_vi, q, missing: 2),
        '24 bài · 24 phút · 2 bài không còn',
      );
      expect(
        savedQueueStatsLine(_en, q, missing: 1),
        '24 songs · 24 min · 1 song gone',
      );
    });

    test('over an hour', () {
      final long = savedQueue(
        'q',
        savedAt: 0,
        ids: List.generate(101, (i) => i + 1),
      ).summary;
      expect(savedQueueStatsLine(_vi, long), '101 bài · 1 giờ 41 phút');
    });
  });

  group('savedQueueSourceLine', () {
    String? line(String? kind, {String? label}) => savedQueueSourceLine(
      _vi,
      SavedQueueInfo(savedAt: 0, contextKind: kind, contextLabel: label),
    );

    test('a named source says its kind', () {
      expect(line('album', label: 'm-tp M-TP'), 'Từ album m-tp M-TP');
      expect(line('artist', label: 'Sơn Tùng'), 'Từ nghệ sĩ Sơn Tùng');
      expect(line('genre', label: 'Indie'), 'Từ thể loại Indie');
      expect(line('language', label: 'Tiếng Việt'), 'Từ ngôn ngữ Tiếng Việt');
      expect(line('folder', label: 'Rap'), 'Từ thư mục Rap');
      expect(line('playlist', label: 'Chạy bộ'), 'Từ playlist Chạy bộ');
    });

    test('sources that need no name', () {
      expect(line('favorites'), 'Từ Yêu thích');
      expect(line('songs'), 'Từ Bài hát');
      expect(line('selection'), 'Từ các bài đã chọn');
    });

    test('History and Most played use their label, else their name', () {
      expect(
        line('mostPlayed', label: 'Phát nhiều nhất · 30 ngày'),
        'Từ Phát nhiều nhất · 30 ngày',
      );
      expect(line('mostPlayed'), 'Từ Phát nhiều nhất');
      expect(line('history'), 'Từ Lịch sử');
    });

    test('no line: no source, a plain queue, an unknown kind, no name', () {
      expect(line(null), isNull);
      expect(line('queue', label: 'x'), isNull);
      expect(line('somethingNew', label: 'x'), isNull);
      expect(line('album'), isNull);
      expect(line('album', label: '   '), isNull);
    });
  });

  group('savedQueuePlayContext', () {
    test('rebuilds the saved source', () {
      expect(
        savedQueuePlayContext(
          const SavedQueueInfo(
            savedAt: 0,
            contextKind: 'album',
            contextRef: 'r',
            contextLabel: 'L',
          ),
        ),
        const PlayContext(PlayContextKind.album, ref: 'r', label: 'L'),
      );
    });

    test('no or unknown source plays as a queue', () {
      const queue = PlayContext(PlayContextKind.queue);
      expect(savedQueuePlayContext(const SavedQueueInfo(savedAt: 0)), queue);
      expect(
        savedQueuePlayContext(
          const SavedQueueInfo(savedAt: 0, contextKind: 'later'),
        ),
        queue,
      );
    });
  });

  test('playable ids keep the played order and skip missing songs', () {
    final detail = savedQueue('q', savedAt: 0, ids: [5, 3, 9, 3], missing: {9});
    expect(savedQueuePlayableIds(detail).map((i) => i.value), [5, 3, 3]);
  });
}
