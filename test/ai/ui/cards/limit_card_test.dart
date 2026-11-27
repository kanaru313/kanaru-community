import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';

import '../support/chat_ui_support.dart';
import 'card_harness.dart';

const _limit = ErrorPart(code: limitReachedCode, kind: 'invalidResponse');

void main() {
  testWidgets('the call that hit the limit is named: no actions', (
    tester,
  ) async {
    final call = writeCall('remove_from_queue', {
      'entryIds': [for (var i = 1; i <= 12; i++) i],
    });
    await pumpCard(
      tester,
      toolRow(
        2,
        state: AiMessageState.error,
        parts: [call, errorResult(call, 'limit reached'), _limit],
      ),
    );
    expect(
      find.text('AI đã đạt giới hạn thay đổi cho tin này'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Mỗi tin chỉ được bỏ tối đa 50 bài và thêm tối đa 200 bài. '
        'Việc “bỏ 12 bài khỏi hàng đợi” không chạy. '
        'Gửi tin mới nếu muốn làm tiếp.',
      ),
      findsOneWidget,
    );
    expectNoButtons();
  });

  testWidgets('a reply over the limit has the card without a call', (
    tester,
  ) async {
    final reply = chatMessage(
      2,
      state: AiMessageState.error,
      parts: const [TextPart('Mình sẽ làm ngay'), _limit],
    );
    await pumpCard(tester, reply);
    expect(
      find.text('AI đã đạt giới hạn thay đổi cho tin này'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Mỗi tin chỉ được bỏ tối đa 50 bài và thêm tối đa 200 bài. '
        'Gửi tin mới nếu muốn làm tiếp.',
      ),
      findsOneWidget,
    );
    // It never retries.
    expect(find.text('Thử lại'), findsNothing);
    expectNoButtons();
  });
}
