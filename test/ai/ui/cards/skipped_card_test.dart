import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';
import 'package:kanaru/src/ai/domain/loop/may_execute.dart';
import 'package:kanaru/src/ai/ui/cards/skipped_card.dart';

import 'card_harness.dart';

final _call = writeCall('create_playlist', {
  'name': 'Giống Lạc trôi',
  'trackIds': [1, 2, 3, 4, 5, 6],
});

const _nothing = 'Tạo playlist “Giống Lạc trôi” · 6 bài · không có gì thay đổi';

/// A call that did not run: [confirm] is its confirm part (none in Auto),
/// [text] what the model was told.
AiMessage _skipped(String text, {ConfirmPart? confirm}) => toolRow(
  2,
  state: AiMessageState.skipped,
  parts: [_call, ?confirm, errorResult(_call, text)],
);

ConfirmPart _confirm(ConfirmStatus status, {String? reason}) =>
    ConfirmPart(callId: _call.id, status: status, reason: reason);

void main() {
  final cases =
      <
        ({
          String name,
          AiMessage message,
          SkipReason reason,
          String title,
          String? why,
        })
      >[
        (
          name: 'declined by the user',
          message: _skipped(
            deniedByUserText,
            confirm: _confirm(ConfirmStatus.denied, reason: 'user'),
          ),
          reason: SkipReason.declined,
          title: 'Đã từ chối',
          why: null,
        ),
        (
          name: 'declined by a new message',
          message: _skipped(
            newMessageText,
            confirm: _confirm(ConfirmStatus.deniedByNewMessage),
          ),
          reason: SkipReason.declinedByNewMessage,
          title: 'Đã từ chối (bạn đã gửi tin khác)',
          why: null,
        ),
        (
          name: 'expired after 24 hours',
          message: _skipped(
            expiredText,
            confirm: _confirm(ConfirmStatus.expired),
          ),
          reason: SkipReason.expired,
          title: 'Đã hết hạn',
          why: 'Thẻ chờ quá 24 giờ. Muốn làm thì nhắn lại cho AI.',
        ),
        (
          name: 'refused by the check once the chat is read-only',
          message: _skipped(
            notAllowedNowText(ExecRefusal.readOnly),
            confirm: _confirm(
              ConfirmStatus.denied,
              reason: ExecRefusal.readOnly.code,
            ),
          ),
          reason: SkipReason.refusedNow,
          title: 'Đã từ chối: không còn được phép',
          why: 'Bạn đã chuyển cuộc này sang Chỉ đọc trước khi việc này chạy.',
        ),
        (
          name: 'refused because the tool group is off',
          message: _skipped(
            notAllowedNowText(ExecRefusal.groupOff),
            confirm: _confirm(
              ConfirmStatus.denied,
              reason: ExecRefusal.groupOff.code,
            ),
          ),
          reason: SkipReason.refusedNow,
          title: 'Đã từ chối: không còn được phép',
          why: 'Bạn đã tắt nhóm công cụ này trước khi việc này chạy.',
        ),
        (
          name: 'refused because the plugin changed',
          message: _skipped(
            notAllowedNowText(ExecRefusal.pluginChanged),
            confirm: _confirm(
              ConfirmStatus.denied,
              reason: ExecRefusal.pluginChanged.code,
            ),
          ),
          reason: SkipReason.refusedNow,
          title: 'Đã từ chối: không còn được phép',
          why: 'Plugin của cuộc này đã đổi trước khi việc này chạy.',
        ),
        (
          name: 'refused because the model changed',
          message: _skipped(
            notAllowedNowText(ExecRefusal.modelChanged),
            confirm: _confirm(
              ConfirmStatus.denied,
              reason: ExecRefusal.modelChanged.code,
            ),
          ),
          reason: SkipReason.refusedNow,
          title: 'Đã từ chối: không còn được phép',
          why: 'Model của cuộc này đã đổi trước khi việc này chạy.',
        ),
        (
          name: 'refused because the call changed after Allow',
          message: _skipped(
            notAllowedNowText(ExecRefusal.hashMismatch),
            confirm: _confirm(
              ConfirmStatus.denied,
              reason: ExecRefusal.hashMismatch.code,
            ),
          ),
          reason: SkipReason.refusedNow,
          title: 'Đã từ chối: không còn được phép',
          why: 'Việc này đã thay đổi sau khi bạn cho phép, nên Kanaru không chạy.',
        ),
        (
          name: 'refused in Auto mode (no confirm part, read from the text)',
          message: _skipped(notAllowedNowText(ExecRefusal.groupOff)),
          reason: SkipReason.refusedNow,
          title: 'Đã từ chối: không còn được phép',
          why: 'Bạn đã tắt nhóm công cụ này trước khi việc này chạy.',
        ),
        (
          name: 'stopped by the user',
          message: _skipped(stoppedByUserText),
          reason: SkipReason.stopped,
          title: 'Không chạy: bạn đã dừng',
          why: null,
        ),
        (
          name: 'a waiting card stopped by the user',
          message: _skipped(
            stoppedByUserText,
            confirm: _confirm(ConfirmStatus.denied),
          ),
          reason: SkipReason.stopped,
          title: 'Không chạy: bạn đã dừng',
          why: null,
        ),
        (
          name: 'skipped after the item limit',
          message: _skipped(limitSkippedText),
          reason: SkipReason.itemLimit,
          title: 'Không chạy',
          why: 'AI đã đạt giới hạn thay đổi cho tin này.',
        ),
        (
          name: 'skipped because the chat grew too large',
          message: _skipped(
            tooLargeSkippedText,
            confirm: _confirm(ConfirmStatus.denied, reason: 'too_large'),
          ),
          reason: SkipReason.tooLarge,
          title: 'Không chạy',
          why: 'Cuộc này quá dài để gửi.',
        ),
        (
          name: 'skipped for a reason this build does not know',
          message: _skipped('not run: something new'),
          reason: SkipReason.other,
          title: 'Không chạy',
          why: null,
        ),
      ];

  for (final c in cases) {
    testWidgets('${c.name}: no actions', (tester) async {
      expect(skipReasonOf(c.message), c.reason);
      await pumpCard(tester, c.message);
      expect(find.text(c.title), findsOneWidget);
      expect(find.text(_nothing), findsOneWidget);
      if (c.why != null) expect(find.text(c.why!), findsOneWidget);
      expectNoButtons();
    });
  }

  testWidgets('a skipped read names the tool, not an action', (tester) async {
    final read = writeCall('search_library', {'query': 'v-pop'});
    final message = toolRow(
      2,
      state: AiMessageState.skipped,
      parts: [read, errorResult(read, stoppedByUserText)],
    );
    await pumpCard(tester, message);
    expect(find.text('Không chạy: bạn đã dừng'), findsOneWidget);
    expect(
      find.text('Tìm trong thư viện · không có gì thay đổi'),
      findsOneWidget,
    );
  });
}
