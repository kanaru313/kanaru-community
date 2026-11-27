import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';

import 'card_harness.dart';

AiMessage _unknown(ToolCallPart call, {String? result}) => toolRow(
  2,
  state: AiMessageState.unknown,
  parts: [call, ?(result == null ? null : errorResult(call, result))],
);

void main() {
  testWidgets('a write cut off by closing the app: no actions', (tester) async {
    final call = writeCall('queue_tracks', {
      'trackIds': [1, 2, 3, 4, 5, 6, 7, 8],
    });
    await pumpCard(tester, _unknown(call));
    expect(
      find.text('Không rõ kết quả: thêm 8 bài vào hàng đợi'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Kanaru bị đóng khi việc này đang chạy nên không biết đã xong chưa. '
        'Xem Hàng đợi trước khi nhờ AI làm lại.',
      ),
      findsOneWidget,
    );
    expectNoButtons();
  });

  testWidgets('a write that timed out says so and points at the playlist', (
    tester,
  ) async {
    final call = writeCall('add_to_playlist', {
      'playlistId': 3,
      'trackIds': [1, 2],
    });
    await pumpCard(tester, _unknown(call, result: writeTimedOutText));
    expect(
      find.text('Không rõ kết quả: thêm 2 bài vào playlist'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Việc này chạy quá lâu nên không biết đã xong chưa. '
        'Xem playlist trước khi nhờ AI làm lại.',
      ),
      findsOneWidget,
    );
    expectNoButtons();
  });
}
