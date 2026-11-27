import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/loop/driver_results.dart';
import 'package:kanaru/src/ai/domain/output/ai_error_code.dart';
import 'package:kanaru/src/ai/domain/output/chat_outcome.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_inputs.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/chat_ui_support.dart';
import 'card_harness.dart';

final _t0 = DateTime(2026, 11, 27, 19, 5);

ChatOutcomeView _view(
  ChatCardKind card, {
  ChatCardAction action = ChatCardAction.retry,
  ChatMessageEnd end = ChatMessageEnd.error,
  String? host,
  DateTime? retryAt,
}) => ChatOutcomeView(
  end: end,
  card: card,
  action: action,
  errorCode: AiErrorCode.server,
  host: host,
  retryAt: retryAt,
);

/// One row of the outcome table: the message the engine stored, what the
/// session still knows of the round (null after a reload), and the card.
typedef _Row = ({
  String name,
  AiMessage message,
  ChatOutcomeView? view,
  String title,
  String? body,
  String? button,
});

AiMessage _stored(
  String code, {
  String kind = 'server',
  AiMessageState state = AiMessageState.error,
  String installId = cardPluginId,
}) => failedRow(2, code: code, kind: kind, state: state, installId: installId);

List<_Row> _rows() => [
  (
    name: 'network names the host',
    message: _stored('network'),
    view: null,
    title: 'Không kết nối được tới api.anthropic.com',
    body: 'Kiểm tra mạng rồi thử lại. Tin của bạn vẫn ở đây.',
    button: 'Thử lại',
  ),
  (
    name: 'network seen live names the host it saw',
    message: _stored('network'),
    view: _view(ChatCardKind.network, host: 'live.example'),
    title: 'Không kết nối được tới live.example',
    body: null,
    button: 'Thử lại',
  ),
  (
    name: 'busy',
    message: _stored('server'),
    view: _view(ChatCardKind.previousTurnBusy),
    title: 'Lượt trước chưa dừng hẳn',
    body: 'Kanaru đang kết thúc lượt trả lời trước. Thử lại sau giây lát.',
    button: 'Thử lại',
  ),
  (
    name: 'third busy asks to restart Kanaru',
    message: _stored('server'),
    view: _view(ChatCardKind.previousTurnStuck),
    title: 'Lượt trước vẫn chưa dừng',
    body:
        'Đã thử 3 lần mà lượt trước vẫn chưa kết thúc. '
        'Khởi động lại Kanaru rồi thử lại.',
    button: 'Thử lại',
  ),
  (
    name: 'bad key',
    message: _stored('key', kind: 'auth'),
    view: null,
    title: 'Claude không nhận API key',
    body:
        'API key sai hoặc đã bị thu hồi. '
        'Sửa trong cài đặt của plugin rồi thử lại.',
    button: 'Mở cài đặt plugin',
  ),
  (
    name: 'quota',
    message: _stored('quota', kind: 'quota'),
    view: null,
    title: 'Tài khoản Claude đã hết hạn mức',
    body: 'Nạp thêm hoặc đổi gói ở trang của nhà cung cấp, rồi thử lại.',
    button: 'Thử lại',
  ),
  (
    name: 'config',
    message: _stored('config'),
    view: null,
    title: 'Cài đặt của Claude chưa đủ',
    body:
        'Plugin báo còn thiếu cài đặt. '
        'Mở cài đặt của plugin để điền rồi thử lại.',
    button: 'Mở cài đặt plugin',
  ),
  (
    name: 'model not found',
    message: _stored('model_not_found'),
    view: null,
    title: 'Model không còn: claude-sonnet-4-5',
    body: 'Claude không còn model này. Chọn model khác rồi thử lại.',
    button: 'Đổi model',
  ),
  (
    name: 'context length',
    message: _stored('context_length', kind: 'invalidResponse'),
    view: null,
    title: 'Cuộc trò chuyện quá dài với model này',
    body:
        'claude-sonnet-4-5 không nhận thêm được. '
        'Mở cuộc mới để tiếp tục; cuộc này vẫn đọc được.',
    button: 'Cuộc trò chuyện mới',
  ),
  (
    name: 'too large to send',
    message: _stored('too_large', kind: 'invalidResponse'),
    view: null,
    title: 'Cuộc này quá dài để gửi',
    body:
        'Kanaru đã rút gọn các lượt cũ mà vẫn quá giới hạn gửi. '
        'Mở cuộc mới, hoặc gửi một tin ngắn hơn.',
    button: 'Cuộc trò chuyện mới',
  ),
  (
    name: 'blocked by the model',
    message: _stored('blocked'),
    view: null,
    title: 'Model không trả lời yêu cầu này',
    body:
        'claude-sonnet-4-5 từ chối (lý do của nhà cung cấp). '
        'Diễn đạt lại, hoặc đổi model ở ô nhập.',
    button: 'Thử lại',
  ),
  (
    name: 'empty answer',
    message: _stored('empty', kind: 'invalidResponse'),
    view: null,
    title: 'Model không trả lời',
    body:
        'claude-sonnet-4-5 trả về câu trả lời trống. '
        'Thử lại, hoặc đổi model ở ô nhập.',
    button: 'Thử lại',
  ),
  (
    name: 'server error',
    message: _stored('server'),
    view: null,
    title: 'Claude gặp lỗi',
    body: 'Dịch vụ báo lỗi (mã: server). Thử lại sau ít phút.',
    button: 'Thử lại',
  ),
  (
    name: 'bad request shows its code',
    message: _stored('bad_request', kind: 'invalidResponse'),
    view: null,
    title: 'Claude gặp lỗi',
    body: 'Dịch vụ báo lỗi (mã: bad_request). Thử lại sau ít phút.',
    button: 'Thử lại',
  ),
  (
    name: 'a code this build does not know is a server error',
    message: _stored('from_the_future'),
    view: null,
    title: 'Claude gặp lỗi',
    body: 'Dịch vụ báo lỗi (mã: server). Thử lại sau ít phút.',
    button: 'Thử lại',
  ),
  (
    name: 'blocked host has no button',
    message: _stored('host_not_allowed'),
    view: null,
    title: 'Plugin không được phép gọi api.anthropic.com',
    body:
        'Địa chỉ này không có trong danh sách plugin đã khai khi cài, '
        'nên Kanaru chặn.',
    button: null,
  ),
  (
    name: 'plugin updated mid-turn',
    message: _stored('plugin_updated', state: AiMessageState.stopped),
    view: null,
    title: 'Plugin vừa được cập nhật',
    body:
        'Claude cập nhật trong lúc trả lời nên lượt này dừng. '
        'Phần đã nhận vẫn ở trên.',
    button: 'Thử lại',
  ),
  (
    name: 'plugin removed mid-turn',
    message: _stored(
      'plugin_removed',
      state: AiMessageState.stopped,
      installId: 'gone',
    ),
    view: null,
    title: 'Plugin đã gỡ',
    body: 'Plugin bị gỡ trong lúc trả lời. Chọn plugin khác để tiếp tục.',
    button: 'Chọn plugin',
  ),
  (
    name: 'broken package',
    message: _stored('server'),
    view: _view(ChatCardKind.pluginBroken, action: ChatCardAction.openPlugin),
    title: 'Plugin hỏng, cần cài lại',
    body: 'Không đọc được gói của Claude. Mở trang plugin để cài lại.',
    button: 'Mở plugin',
  ),
  (
    name: '300 s timeout',
    message: _stored('server', state: AiMessageState.stopped),
    view: _view(ChatCardKind.timeout, end: ChatMessageEnd.stopped),
    title: 'Hết thời gian chờ',
    body:
        'Claude không gửi thêm gì nên lượt này dừng. '
        'Phần đã nhận vẫn ở trên.',
    button: 'Thử lại',
  ),
  (
    name: 'plugin crashed',
    message: _stored('server'),
    view: _view(ChatCardKind.pluginError),
    title: 'Plugin gặp lỗi',
    body:
        'Claude dừng giữa chừng vì lỗi bên trong plugin. '
        'Thử lại; nếu lặp lại, xem nhật ký của plugin.',
    button: 'Thử lại',
  ),
  (
    name: 'closing the app cut the answer off',
    message: _stored(
      'cutOffByClose',
      kind: 'closed',
      state: AiMessageState.stopped,
    ),
    view: null,
    title: 'Lượt trả lời bị ngắt khi đóng Kanaru',
    body:
        'Phần đã nhận vẫn ở trên. Kanaru không tự gửi lại khi mở; '
        'bấm Thử lại để AI làm tiếp.',
    button: 'Thử lại',
  ),
];

int _retries(CardSetup s) => s.session.calls.where((c) => c == 'retry').length;

void main() {
  for (final row in _rows()) {
    testWidgets('outcome row: ${row.name}', (tester) async {
      final setup = await pumpCard(
        tester,
        row.message,
        messages: [userRow(1), row.message],
        view: row.view,
      );
      expect(find.text(row.title), findsOneWidget);
      if (row.body != null) expect(find.text(row.body!), findsOneWidget);
      if (row.button == null) {
        expectNoButtons();
      } else {
        expect(find.text(row.button!), findsOneWidget);
        expectButtonAtEnd(tester, row.button!);
      }
      expect(setup.session.calls.where((c) => c != 'open 1'), isEmpty);
    });
  }

  group('what the buttons do', () {
    testWidgets('Thử lại retries the turn once, however often it is tapped', (
      tester,
    ) async {
      final row = _stored('server');
      final setup = await pumpCard(tester, row, messages: [userRow(1), row]);
      await tester.tap(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await settle(tester);
      expect(_retries(setup), 1);
    });

    testWidgets('Thử lại can be tried again when the turn did not start', (
      tester,
    ) async {
      final row = _stored('server');
      final setup = await pumpCard(tester, row, messages: [userRow(1), row]);
      setup.session.retryResult = const DriverBusy();
      await tester.tap(find.text('Thử lại'));
      await settle(tester);
      await tester.tap(find.text('Thử lại'));
      await settle(tester);
      expect(_retries(setup), 2);
    });

    testWidgets('the cut-off card offers Thử lại', (tester) async {
      final row = _stored(
        'cutOffByClose',
        kind: 'closed',
        state: AiMessageState.stopped,
      );
      final setup = await pumpCard(tester, row, messages: [userRow(1), row]);
      await tester.tap(find.text('Thử lại'));
      await settle(tester);
      expect(_retries(setup), 1);
    });

    testWidgets('Mở cài đặt plugin opens the plugin page', (tester) async {
      final row = _stored('key', kind: 'auth');
      final setup = await pumpCard(tester, row, messages: [userRow(1), row]);
      await tester.tap(find.text('Mở cài đặt plugin'));
      await settle(tester);
      expect(setup.host.calls, ['openSettings /settings/plugins/p/plugin-1']);
    });

    testWidgets('Mở plugin opens the plugin page', (tester) async {
      final row = _stored('server');
      final setup = await pumpCard(
        tester,
        row,
        messages: [userRow(1), row],
        view: _view(
          ChatCardKind.pluginBroken,
          action: ChatCardAction.openPlugin,
        ),
      );
      await tester.tap(find.text('Mở plugin'));
      await settle(tester);
      expect(setup.host.calls, ['openSettings /settings/plugins/p/plugin-1']);
    });

    testWidgets('Đổi model asks for the model picker', (tester) async {
      final row = _stored('model_not_found');
      final setup = await pumpCard(tester, row, messages: [userRow(1), row]);
      expect(setup.container.read(modelPickerRequestProvider), isFalse);
      await tester.tap(find.text('Đổi model'));
      await settle(tester);
      expect(setup.container.read(modelPickerRequestProvider), isTrue);
    });

    testWidgets('Cuộc trò chuyện mới opens a new conversation', (tester) async {
      final row = _stored('context_length', kind: 'invalidResponse');
      final setup = await pumpCard(tester, row, messages: [userRow(1), row]);
      await tester.tap(find.text('Cuộc trò chuyện mới'));
      await settle(tester);
      expect(setup.session.calls, contains('new'));
    });

    testWidgets('Chọn plugin opens the plugin picker', (tester) async {
      final row = _stored(
        'plugin_removed',
        state: AiMessageState.stopped,
        installId: 'gone',
      );
      await pumpCard(tester, row, messages: [userRow(1), row]);
      await tester.tap(find.text('Chọn plugin'));
      await settle(tester);
      expect(
        find.text('Áp dụng từ tin nhắn tiếp theo. Lịch sử giữ nguyên.'),
        findsOneWidget,
      );
    });

    testWidgets('too_large never enables retry', (tester) async {
      final row = _stored('too_large', kind: 'invalidResponse');
      await pumpCard(tester, row, messages: [userRow(1), row]);
      expect(find.text('Thử lại'), findsNothing);
      expect(find.textContaining('Thử lại sau'), findsNothing);
    });
  });

  group('countdown', () {
    AiMessage rate(Duration left) => failedRow(
      2,
      code: 'rate_limit',
      kind: 'rateLimited',
      retryAt: _t0.add(left),
    );

    testWidgets('countdown enables retry at pause end (fake clock)', (
      tester,
    ) async {
      var now = _t0;
      final row = rate(const Duration(seconds: 28));
      final setup = await pumpCard(
        tester,
        row,
        messages: [userRow(1), row],
        clock: () => now,
      );
      expect(find.text('Claude đang giới hạn số yêu cầu'), findsOneWidget);
      expect(
        find.text(
          'Plugin báo lỗi 429 (quá nhiều yêu cầu). '
          'Hết đếm ngược thì bấm Thử lại; Kanaru không tự gửi lại.',
        ),
        findsOneWidget,
      );
      expect(find.text('Thử lại sau 28 giây'), findsOneWidget);
      // Locked while counting.
      await tester.tap(find.text('Thử lại sau 28 giây'), warnIfMissed: false);
      await settle(tester);
      expect(_retries(setup), 0);

      now = _t0.add(const Duration(seconds: 29));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.textContaining('Thử lại sau'), findsNothing);
      // Nothing was sent by itself.
      expect(_retries(setup), 0);
      await tester.tap(find.text('Thử lại'));
      await settle(tester);
      expect(_retries(setup), 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the label follows the time left', (tester) async {
      for (final (left, label) in [
        (const Duration(seconds: 28), 'Thử lại sau 28 giây'),
        (const Duration(seconds: 90), 'Thử lại sau 1 phút 30 giây'),
        (const Duration(minutes: 2), 'Thử lại sau 2 phút'),
        (const Duration(hours: 2), 'Thử lại lúc 21:05'),
      ]) {
        final row = rate(left);
        await pumpCard(
          tester,
          row,
          messages: [userRow(1), row],
          clock: () => _t0,
        );
        expect(find.text(label), findsOneWidget, reason: label);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a pause seen live counts down to its end', (tester) async {
      final row = _stored('rate_limit', kind: 'rateLimited');
      await pumpCard(
        tester,
        row,
        messages: [userRow(1), row],
        view: _view(
          ChatCardKind.rateLimited,
          retryAt: _t0.add(const Duration(seconds: 45)),
        ),
        clock: () => _t0,
      );
      expect(find.text('Claude đang giới hạn số yêu cầu'), findsOneWidget);
      expect(find.text('Thử lại sau 45 giây'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a limit with no end time offers retry at once', (
      tester,
    ) async {
      final row = _stored('rate_limit', kind: 'rateLimited');
      await pumpCard(tester, row, messages: [userRow(1), row]);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(
        find.text(
          'Plugin báo lỗi 429 (quá nhiều yêu cầu). '
          'Đợi một lúc rồi bấm Thử lại; Kanaru không tự gửi lại.',
        ),
        findsOneWidget,
      );
    });
  });

  group('older turns', () {
    testWidgets("old turn's card has no live actions", (tester) async {
      final row = failedRow(
        2,
        code: 'rate_limit',
        kind: 'rateLimited',
        retryAt: _t0.add(const Duration(seconds: 28)),
      );
      await pumpCard(
        tester,
        row,
        messages: [userRow(1), row, userRow(3)],
        clock: () => _t0,
      );
      expect(find.text('Claude đang giới hạn số yêu cầu'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
      expect(find.textContaining('Thử lại sau'), findsNothing);
      expectNoButtons();
      // No ticker: the binding fails the test if a timer is pending.
    });

    testWidgets("an old turn's settings link is not live either", (
      tester,
    ) async {
      final row = _stored('key', kind: 'auth');
      await pumpCard(tester, row, messages: [userRow(1), row, userRow(3)]);
      expect(find.text('Mở cài đặt plugin'), findsNothing);
    });

    testWidgets('a retried round makes the earlier card read-only', (
      tester,
    ) async {
      final failed = _stored('server');
      final retried = chatMessage(3, state: AiMessageState.streaming);
      await pumpCard(tester, failed, messages: [userRow(1), failed, retried]);
      expect(find.text('Claude gặp lỗi'), findsOneWidget);
      expectNoButtons();
    });
  });

  testWidgets('a plain stop draws no card', (tester) async {
    final stopped = chatMessage(
      2,
      state: AiMessageState.stopped,
      parts: const [],
    );
    await pumpCard(tester, stopped, messages: [userRow(1), stopped]);
    expect(find.byType(KActionCard), findsNothing);
  });
}
