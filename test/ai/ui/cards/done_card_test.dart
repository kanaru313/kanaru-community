import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/state/chat_session.dart' show ReplayResult;

import '../support/chat_list_harness.dart' show fakeTrack;
import 'card_harness.dart';

ToolResultPart _result(ToolCallPart call, String json) =>
    ToolResultPart(id: call.id, name: call.name, content: [TextPart(json)]);

AiMessage _done(
  ToolCallPart call,
  DonePart done, {
  String result = '{}',
  bool askedFirst = false,
}) => toolRow(
  2,
  state: AiMessageState.done,
  parts: [
    call,
    if (askedFirst) ConfirmPart(callId: call.id, status: ConfirmStatus.allowed),
    _result(call, result),
    done,
  ],
);

final _play = writeCall('play_tracks', {
  'trackIds': [1, 2, 3],
});

DonePart _replaced() => DonePart(
  callId: _play.id,
  added: songsOf(3),
  replacedQueue: const ReplacedQueueSnapshot(
    tracks: [10, 11, 12],
    userOrder: [10, 11, 12],
    shuffled: false,
  ),
);

void main() {
  testWidgets('removed list equals returned entries', (tester) async {
    final call = writeCall('remove_from_queue', {
      'entryIds': [1, 2, 3, 4],
    });
    // Four were asked for; the player removed three of them.
    await pumpCard(
      tester,
      _done(call, DonePart(callId: call.id, removed: songsOf(3))),
    );
    expect(find.text('Đã làm: bỏ 3 bài khỏi hàng đợi'), findsOneWidget);
    expect(
      find.text('Tự động · Sửa hàng đợi · 1 bài đã không còn trong hàng đợi'),
      findsOneWidget,
    );
    expect(find.text('3 bài đã bỏ'), findsOneWidget);
    expect(find.text('Bài 0'), findsNothing);
    await tester.tap(find.text('3 bài đã bỏ'));
    await settle(tester);
    expect(find.text('Bài 0'), findsOneWidget);
    expect(find.text('Bài 2'), findsOneWidget);
    expect(find.text('Bài 3'), findsNothing);
    expect(find.text('Mở hàng đợi'), findsOneWidget);
  });

  testWidgets('removals from a playlist tell what was already gone', (
    tester,
  ) async {
    final call = writeCall('remove_from_playlist', {
      'playlistId': 4,
      'entryIds': [1, 2, 3],
    });
    await pumpCard(
      tester,
      _done(
        call,
        DonePart(callId: call.id, removed: songsOf(2)),
        result: '{"playlistId":4,"removed":2}',
        askedFirst: true,
      ),
    );
    expect(find.text('Đã làm: bỏ 2 bài khỏi playlist'), findsOneWidget);
    expect(
      find.text(
        'Bạn đã cho phép · Sửa playlist · 1 bài đã không còn trong playlist',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the added list is folded and Xem opens the playlist', (
    tester,
  ) async {
    final call = writeCall('create_playlist', {
      'name': 'Giống Lạc trôi',
      'trackIds': [100, 101, 102, 103, 104, 105],
    });
    final setup = await pumpCard(
      tester,
      _done(
        call,
        DonePart(callId: call.id, added: songsOf(6)),
        result: '{"playlistId":7,"name":"Giống Lạc trôi","tracks":6}',
        askedFirst: true,
      ),
    );
    expect(
      find.text('Đã làm: tạo playlist “Giống Lạc trôi” · 6 bài'),
      findsOneWidget,
    );
    expect(find.text('Bạn đã cho phép · Tạo playlist'), findsOneWidget);
    expect(find.text('6 bài đã thêm'), findsOneWidget);
    expect(find.text('Bài 0'), findsNothing);
    await tester.tap(find.text('6 bài đã thêm'));
    await settle(tester);
    expect(find.text('Bài 5'), findsOneWidget);
    await tester.tap(find.text('Xem'));
    await settle(tester);
    expect(setup.host.calls, ['openSettings /playlists/p7']);
  });

  testWidgets('Xem falls back to the playlists when the id is unknown', (
    tester,
  ) async {
    final call = writeCall('create_playlist', {
      'name': 'Mưa',
      'trackIds': [1],
    });
    final setup = await pumpCard(
      tester,
      _done(
        call,
        DonePart(callId: call.id, added: songsOf(1)),
        result: '{"name":"Mưa","tracks":1,"note":"created"}',
      ),
    );
    expect(find.text('Tự động · Tạo playlist'), findsOneWidget);
    await tester.tap(find.text('Xem'));
    await settle(tester);
    expect(setup.host.calls, ['openSettings /playlists']);
  });

  testWidgets('a long replaced queue loads the rows that "+N bài" opens', (
    tester,
  ) async {
    final ids = [for (var i = 1; i <= 12; i++) 100 + i];
    final call = _play;
    await pumpCard(
      tester,
      _done(
        call,
        DonePart(
          callId: call.id,
          added: songsOf(3),
          replacedQueue: ReplacedQueueSnapshot(
            tracks: ids,
            userOrder: ids,
            shuffled: false,
          ),
        ),
      ),
      library: {for (final id in ids) id: fakeTrack(id, title: 'Cũ $id')},
    );
    await tester.tap(find.text('Hàng đợi cũ · 12 bài'));
    await settle(tester);
    expect(find.text('Cũ 101'), findsOneWidget);
    expect(find.text('Cũ 106'), findsNothing);
    await tester.tap(find.text('+7 bài'));
    await settle(tester);
    for (final id in ids.skip(5)) {
      expect(find.text('Cũ $id'), findsOneWidget);
    }
    expect(find.text('Không còn trong thư viện'), findsNothing);
  });

  testWidgets('a replaced queue folds the old queue and offers the replay', (
    tester,
  ) async {
    await pumpCard(
      tester,
      _done(_play, _replaced()),
      library: {
        10: fakeTrack(10, title: 'Nàng thơ', artist: 'Hoàng Dũng'),
        11: fakeTrack(11, title: 'Bước qua nhau', artist: 'Vũ.'),
      },
    );
    expect(find.text('Đã làm: phát 3 bài'), findsOneWidget);
    expect(
      find.text('Tự động · Điều khiển phát · hàng đợi cũ đã được thay'),
      findsOneWidget,
    );
    expect(find.text('Hàng đợi cũ · 3 bài'), findsOneWidget);
    expect(find.text('Phát lại hàng đợi cũ'), findsOneWidget);
    expect(find.text('Mở hàng đợi'), findsOneWidget);
    await tester.tap(find.text('Hàng đợi cũ · 3 bài'));
    await settle(tester);
    expect(find.text('Nàng thơ'), findsOneWidget);
    expect(find.text('Bước qua nhau'), findsOneWidget);
    // A song of the old queue that left the library is told so.
    expect(find.text('Không còn trong thư viện'), findsOneWidget);
  });

  testWidgets('replay old queue calls replayQueue', (tester) async {
    final setup = await pumpCard(tester, _done(_play, _replaced()));
    await tester.tap(find.text('Phát lại hàng đợi cũ'));
    await settle(tester);
    expect(setup.session.calls.where((c) => c.startsWith('replay')), [
      'replay 2',
    ]);
  });

  testWidgets('replay old queue only on the latest turn', (tester) async {
    final card = _done(_play, _replaced());
    final setup = await pumpCard(tester, card, messages: [card, userRow(3)]);
    expect(find.text('Phát lại hàng đợi cũ'), findsNothing);
    // Opening the queue stays on an old turn.
    await tester.tap(find.text('Mở hàng đợi'));
    await settle(tester);
    expect(setup.host.calls, ['openQueue']);
    expect(setup.session.calls.where((c) => c.startsWith('replay')), isEmpty);
  });

  testWidgets('a failed replay leaves the button ready for another try', (
    tester,
  ) async {
    final setup = await pumpCard(tester, _done(_play, _replaced()));
    setup.session.replayResult = ReplayResult.failed;
    await tester.tap(find.text('Phát lại hàng đợi cũ'));
    await settle(tester);
    await tester.tap(find.text('Phát lại hàng đợi cũ'));
    await settle(tester);
    expect(setup.session.calls.where((c) => c.startsWith('replay')), [
      'replay 2',
      'replay 2',
    ]);
  });

  testWidgets('ids that were not songs are told', (tester) async {
    final call = writeCall('queue_tracks', {
      'trackIds': [1, 2, 3, 4],
    });
    await pumpCard(
      tester,
      _done(
        call,
        DonePart(callId: call.id, added: songsOf(2), absent: const [3, 4]),
      ),
    );
    expect(find.text('Đã làm: thêm 2 bài vào hàng đợi'), findsOneWidget);
    expect(
      find.text('Tự động · Sửa hàng đợi · 2 bài không có trong thư viện'),
      findsOneWidget,
    );
  });
}
