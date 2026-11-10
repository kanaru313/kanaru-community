import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/playback/domain/playable.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/shell/ui/playback_notice_listener.dart';
import 'package:material_ui/material_ui.dart';

import '../playback/support/ui_host.dart';

void main() {
  test('every notice has words in both languages', () {
    final en = AppLocalizationsEn();
    final vi = AppLocalizationsVi();
    const skipped = TrackSkipped('Song', UnplayableReason.missing, 1);
    const many = TrackSkipped('Song', UnplayableReason.missing, 3);
    expect(noticeText(en, skipped), 'Skipped “Song”: file is gone');
    expect(noticeText(vi, skipped), 'Bỏ qua “Song”: tệp không còn');
    expect(noticeText(en, many), contains('2 more'));
    expect(noticeText(vi, many), contains('2 bài nữa'));
    expect(noticeText(en, const TrackFailed('Song')), 'Could not play “Song”');
    expect(noticeText(vi, const TrackFailed('Song')), 'Không phát được “Song”');
    expect(noticeText(en, const FirstTrack()), 'This is the first track');
    expect(noticeText(vi, const FirstTrack()), 'Đây là bài đầu');
    expect(noticeText(en, const QueueEnd()), 'End of the queue');
    expect(noticeText(vi, const QueueEnd()), 'Hết hàng đợi');
    expect(noticeText(en, const QueueEmpty()), 'The queue is empty');
    expect(noticeText(vi, const QueueEmpty()), 'Hàng đợi trống');
    expect(
      noticeText(vi, const FocusDenied()),
      'Không phát được: ứng dụng khác đang dùng âm thanh',
    );
    expect(noticeText(en, const FocusDenied()), contains('another app'));
  });

  testWidgets('a notice becomes a snack bar while a track is current', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const PlaybackNoticeListener(child: Text('page')),
    );
    expect(find.byType(SnackBar), findsNothing);
    // Previous at the first entry raises the "first track" notice.
    await tester.pump();
    await host.run(tester, host.h.c.previous);
    await host.letStreamsArrive(tester);
    expect(find.text('This is the first track'), findsOneWidget);
  });

  testWidgets('a notice is still shown after the last track is gone', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const PlaybackNoticeListener(child: Text('page')),
    );
    final entries = host.h.c.queueState.items.map((i) => i.entryId).toSet();
    await host.run(tester, () async {
      await host.h.c.remove(entries);
    });
    // No track now; Play on the empty queue raises "queue empty".
    await host.run(tester, host.h.c.play);
    await host.letStreamsArrive(tester);
    expect(find.text('The queue is empty'), findsOneWidget);
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('a listener that was not started shows nothing', (tester) async {
    final host = await pumpWithPlayer(
      tester,
      const PlaybackNoticeListener(autoStart: false, child: Text('page')),
      play: false,
    );
    await host.run(tester, host.h.c.play);
    await host.letStreamsArrive(tester);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('start() listens at once, in the caller\'s frame', (
    tester,
  ) async {
    final key = GlobalKey<PlaybackNoticeListenerState>();
    final host = await pumpWithPlayer(
      tester,
      PlaybackNoticeListener(
        key: key,
        autoStart: false,
        child: const Text('page'),
      ),
    );
    key.currentState!.start();
    // A second start does not subscribe twice.
    key.currentState!.start();
    await host.run(tester, host.h.c.previous);
    await host.letStreamsArrive(tester);
    expect(find.text('This is the first track'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('the same notice twice shows twice', (tester) async {
    final host = await pumpWithPlayer(
      tester,
      const PlaybackNoticeListener(child: Text('page')),
    );
    await tester.pump();
    await host.run(tester, host.h.c.previous);
    await host.letStreamsArrive(tester);
    expect(find.text('This is the first track'), findsOneWidget);
    // Clear the first toast, then raise the very same (const) notice again.
    ScaffoldMessenger.of(tester.element(find.text('page'))).clearSnackBars();
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    await host.run(tester, host.h.c.previous);
    await host.letStreamsArrive(tester);
    expect(find.text('This is the first track'), findsOneWidget);
  });
}
