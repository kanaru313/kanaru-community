import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_labels.dart';
import 'package:kanaru/src/lyrics/ui/online/online_labels.dart';
import 'package:kanaru/src/lyrics/ui/online/online_row_info.dart';
import 'package:kanaru/src/lyrics/ui/online/plugin_avatar.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart' show syncedLyrics;
import 'online_ui_overrides.dart';

final _en = AppLocalizationsEn();
final _vi = AppLocalizationsVi();

OnlineRowInfo _info({
  OnlineHow how = OnlineHow.auto,
  bool synced = true,
  bool instrumental = false,
  Duration? duration = const Duration(minutes: 4, seconds: 12),
}) => OnlineRowInfo(
  providerId: 'netease',
  providerName: 'NetEase',
  how: how,
  selected: true,
  synced: synced,
  instrumental: instrumental,
  duration: duration,
);

void main() {
  group('onlineRowSubtitle', () {
    test('Vietnamese, exactly as the mockup words it', () {
      expect(
        onlineRowSubtitle(_vi, _info(), removed: false),
        'NetEase · Đồng bộ · 4:12 · tự tìm',
      );
      expect(
        onlineRowSubtitle(
          _vi,
          _info(how: OnlineHow.kept, synced: false),
          removed: false,
        ),
        'NetEase · Thường · 4:12',
      );
      expect(
        onlineRowSubtitle(_vi, _info(how: OnlineHow.kept), removed: true),
        'NetEase · plugin đã gỡ · Đồng bộ · 4:12',
      );
    });

    test('no duration, seconds are padded, instrumental has no kind', () {
      expect(
        onlineRowSubtitle(_en, _info(duration: null), removed: false),
        'NetEase · Synced · found automatically',
      );
      expect(
        onlineRowSubtitle(
          _en,
          _info(duration: const Duration(minutes: 3, seconds: 5)),
          removed: false,
        ),
        'NetEase · Synced · 3:05 · found automatically',
      );
      expect(
        onlineRowSubtitle(_en, _info(instrumental: true), removed: false),
        'NetEase · Instrumental · 4:12 · found automatically',
      );
    });
  });

  group('lyricsLabelOf', () {
    test('local lyrics keep their words', () {
      expect(
        lyricsLabelOf(_vi, LyricsShown(syncedLyrics(1))),
        'Lời trong tag · Đồng bộ',
      );
      expect(
        lyricsLabelOf(_vi, LyricsShown(syncedLyrics(1)), short: true),
        'Trong tag',
      );
    });

    test('online lyrics: "<plugin> · Đồng bộ"; short is the plugin', () {
      final online = LyricsShown(onlineLyrics());
      expect(lyricsLabelOf(_vi, online), 'NetEase · Đồng bộ');
      expect(lyricsLabelOf(_vi, online, short: true), 'NetEase');
      expect(
        lyricsLabelOf(_vi, LyricsShown(onlineLyrics(synced: false))),
        'NetEase · Thường',
      );
    });

    test('lookup states name themselves; the card has no short word', () {
      expect(lyricsLabelOf(_vi, const LyricsSearching(1)), 'Đang tìm…');
      expect(
        lyricsLabelOf(
          _vi,
          const LyricsLookupFailed(reason: LookupFailReason.network, asked: 1),
        ),
        'Chưa tìm được lời',
      );
      expect(
        lyricsLabelOf(_vi, LyricsLookupPaused(DateTime(2030))),
        'Nguồn lời tạm dừng',
      );
      expect(lyricsLabelOf(_vi, const LyricsSearching(1), short: true), '');
      expect(lyricsLabelOf(_vi, const LyricsNone()), 'Không có lời');
    });
  });

  group('failure reasons', () {
    test('long and short texts per reason (Vietnamese)', () {
      expect(
        failReasonLong(_vi, LookupFailReason.network, 2),
        'Lỗi mạng khi tìm ở 2 nguồn đang bật',
      );
      expect(
        failReasonLong(_vi, LookupFailReason.needsConfig, 2),
        'Các nguồn cần cấu hình',
      );
      expect(
        failReasonLong(_vi, LookupFailReason.noAnswer, 2),
        'Nguồn lời không trả lời',
      );
      expect(failReasonShort(_vi, LookupFailReason.network), 'lỗi mạng');
    });
  });

  group('onlineRowInfoOf', () {
    test('shown online lyrics: selected, with their kind and duration', () {
      final info = onlineRowInfoOf(LyricsShown(onlineLyrics()), null)!;
      expect(info.selected, isTrue);
      expect(info.autoShown, isTrue);
      expect(info.keptShown, isFalse);
      expect(info.synced, isTrue);
      expect(info.duration, const Duration(minutes: 4, seconds: 12));
    });

    test('a kept copy shown is "kept"', () {
      final info = onlineRowInfoOf(
        LyricsShown(onlineLyrics(how: OnlineHow.kept)),
        null,
      )!;
      expect(info.keptShown, isTrue);
      expect(info.autoShown, isFalse);
    });

    test('instrumental: selected, flagged', () {
      final info = onlineRowInfoOf(
        LyricsInstrumental(onlineLyrics().online!),
        null,
      )!;
      expect(info.selected, isTrue);
      expect(info.instrumental, isTrue);
    });

    test('off with an online copy available: offered, not selected', () {
      final info = onlineRowInfoOf(
        LyricsOff(onlineLyrics(how: OnlineHow.kept)),
        null,
      )!;
      expect(info.selected, isFalse);
      expect(info.how, OnlineHow.kept);
    });

    test('file lyrics shown beside a kept copy: the copy, not selected', () {
      final info = onlineRowInfoOf(
        LyricsShown(syncedLyrics(1)),
        keptPick(synced: false),
      )!;
      expect(info.selected, isFalse);
      expect(info.how, OnlineHow.kept);
      expect(info.synced, isFalse);
    });

    test('nothing online: no row', () {
      expect(onlineRowInfoOf(LyricsShown(syncedLyrics(1)), null), isNull);
      expect(onlineRowInfoOf(const LyricsNone(), null), isNull);
      expect(onlineRowInfoOf(const LyricsLoading(), null), isNull);
    });
  });

  group('PluginAvatar', () {
    final png = Uint8List.fromList(const [1, 2, 3]);

    Future<void> pump(
      WidgetTester tester, {
      required String id,
      bool loaded = true,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: onlineUiOverrides(
            sources: [lyricsSource('netease')],
            icons: {'netease': png, 'zing': png},
            loaded: loaded,
          ),
          child: MaterialApp(
            theme: buildKanaruTheme(brightness: Brightness.light),
            home: Scaffold(
              body: PluginAvatar(providerId: id, name: 'Name', size: 24),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('an installed plugin shows its icon bytes', (tester) async {
      await pump(tester, id: 'netease');
      final avatar = tester.widget<KSourceAvatar>(find.byType(KSourceAvatar));
      expect(avatar.imageBytes, png);
      expect(avatar.removed, isFalse);
    });

    testWidgets('a removed plugin shows no icon even if one is cached', (
      tester,
    ) async {
      await pump(tester, id: 'zing');
      final avatar = tester.widget<KSourceAvatar>(find.byType(KSourceAvatar));
      expect(avatar.removed, isTrue);
      expect(avatar.imageBytes, isNull);
    });

    testWidgets('before the plugin list is known nothing is "removed"', (
      tester,
    ) async {
      await pump(tester, id: 'zing', loaded: false);
      expect(
        tester.widget<KSourceAvatar>(find.byType(KSourceAvatar)).removed,
        isFalse,
      );
    });
  });
}
