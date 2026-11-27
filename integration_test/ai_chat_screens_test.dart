import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/state/chat_attachments.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_draft.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_inputs.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_view.dart';
import 'package:material_ui/material_ui.dart';

import '../test/ai/ui/cards/card_harness.dart'
    show failedRow, songsOf, toolRow, userRow, writeCall;
import '../test/ai/ui/composer/composer_harness.dart' show chatPlugin;
import '../test/ai/ui/support/chat_list_harness.dart' show fakeTrack;
import '../test/ai/ui/support/chat_ui_support.dart';
import '../test/support/icon_button_finders.dart';
import '../test/support/kanaru_ui_finders.dart';
import 'support/ai_chat_harness.dart';

/// AI chat screens (PR #116, polish #118, #119) in Vietnamese, on both shells:
/// the phone (412 x 915, MobileShell, the `/chat` page) and the desktop
/// (1400 x 1000, DesktopShell, chat in the right panel). The real shell,
/// router and chat widgets run over the fake engine of `test/ai/ui/support`
/// (no plugin, no network, no native library), so the same file runs as a
/// plain widget test and on the Linux device.
///
/// It asserts state (finders, semantics), never pixels. Screenshots
/// `NN-<state>-<shell>.png` go to `$KANARU_IT_SHOTS` (default
/// `/tmp/kanaru-it/shots-ai-chat`) for comparing with `mockups/*/08-ai-chat`.
///
/// This file: empty and not-ready states, answers, tool cards, composer and
/// error cards. History and the entry points are in `ai_chat_history_test.dart`
/// and `ai_chat_entry_test.dart`; shared setup in `support/ai_chat_harness.dart`.
///
/// Run as a widget test:
/// `flutter test integration_test/ai_chat_screens_test.dart -d flutter-tester`

AiMessage _user(int id, String text) =>
    chatMessage(id, role: AiMessageRole.user, parts: [TextPart(text)]);

AiMessage _answer(
  int id,
  List<AiPart> parts, {
  AiMessageState state = AiMessageState.complete,
}) => chatMessage(id, parts: parts, state: state, model: 'claude-sonnet-4-5');

AiMessage _toolResult(int id, String name, String json) => chatMessage(
  id,
  role: AiMessageRole.tool,
  state: AiMessageState.done,
  parts: [
    ToolCallPart.parsed(id: 'c$id', name: name, args: const {}),
    ToolResultPart(id: 'c$id', name: name, content: [TextPart(json)]),
  ],
);

final _createCall = writeCall('create_playlist', {
  'name': 'Giống Lạc trôi',
  'trackIds': [100, 101, 102, 103, 104, 105],
});

AiMessage _confirmRow({
  AiMessageState state = AiMessageState.pending,
  ConfirmStatus status = ConfirmStatus.pending,
}) => toolRow(
  2,
  state: state,
  parts: [
    _createCall,
    ConfirmPart(callId: _createCall.id, status: status),
  ],
);

AiMessage _skippedRow(String text, ConfirmStatus? status) => toolRow(
  2,
  state: AiMessageState.skipped,
  parts: [
    _createCall,
    if (status != null) ConfirmPart(callId: _createCall.id, status: status),
    errorResult(_createCall, text),
  ],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('empty and not ready', () {
    perShell('no AI plugin: the guide, no composer, no MCP', (
      tester,
      shell,
    ) async {
      final handle = tester.ensureSemantics();
      final c = await openChat(tester, shell, plugins: const [], bind: false);
      expect(find.text('Chọn một dịch vụ AI'), findsOneWidget);
      expect(find.text('Mở kho plugin AI'), findsOneWidget);
      expect(find.textContaining('MCP'), findsNothing);
      expect(byEnabledState('Gửi', enabled: true), findsNothing);
      expect(byEnabledState('Gửi', enabled: false), findsNothing);
      handle.dispose();
      await c.shot('01-no-plugin');
    });

    perShell('needs a key: notice and Send disabled', (tester, shell) async {
      final handle = tester.ensureSemantics();
      final c = await openChat(
        tester,
        shell,
        readiness: const ChatNeedsKey(),
        model: null,
      );
      expect(find.textContaining('cần API key trước khi gửi'), findsOneWidget);
      expect(find.text('Mở cài đặt plugin'), findsOneWidget);
      expect(byEnabledState('Gửi', enabled: false), findsOneWidget);
      await c.shot('02-needs-key');
      handle.dispose();
    });

    perShell('needs a model: notice offers Chọn model', (tester, shell) async {
      final c = await openChat(
        tester,
        shell,
        readiness: const ChatNeedsModel(),
        model: null,
      );
      expect(find.textContaining('chưa có model'), findsOneWidget);
      expect(find.text('Chọn model'), findsWidgets);
      await c.shot('03-needs-model');
    });

    perShell('new conversation: prompt chips and a suggested page chip', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      expect(find.text('Hỏi gì về nhạc của bạn?'), findsOneWidget);
      // The six built-in prompts; the fifth is Dịch lời.
      for (final name in const [
        'Giải nghĩa lời',
        'Về bài này',
        'Bài tương tự trong thư viện',
        'Playlist theo mood',
        'Tóm tắt thói quen nghe',
        'Dịch lời',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      c.container.read(chatAttachmentsProvider.notifier).setSuggestions(const [
        ChipPart(kind: ChipKind.album, ref: 'k', label: 'Blue'),
      ]);
      await c.pump();
      expect(find.textContaining('Album: Blue'), findsOneWidget);
      await c.shot('04-new-empty');
    });
  });

  group('answers', () {
    perShell('streaming: dots, partial text, Stop replaces Send', (
      tester,
      shell,
    ) async {
      final handle = tester.ensureSemantics();
      final c = await openChat(tester, shell);
      await c.messages([
        _user(1, 'Gợi ý vài bài buồn'),
        _answer(2, const [
          TextPart('Mình đang tìm vài bài'),
        ], state: AiMessageState.streaming),
      ]);
      c.session.setTurn(TurnState.streaming);
      c.container
          .read(fakeLiveTextProvider.notifier)
          .set('Mình đang tìm vài bài hợp tâm trạng của anh');
      await c.pump();
      expect(find.semantics.byLabel('Đang trả lời'), findsOneWidget);
      expect(byEnabledState('Dừng', enabled: true), findsOneWidget);
      expect(byEnabledState('Gửi', enabled: true), findsNothing);
      await c.shot('05-streaming');
      handle.dispose();
    });

    perShell('stopped answer keeps its text with Đã dừng, no card', (
      tester,
      shell,
    ) async {
      final handle = tester.ensureSemantics();
      final c = await openChat(tester, shell);
      await c.messages([
        _user(1, 'Gợi ý vài bài buồn'),
        _answer(2, const [
          TextPart('Mình đã tìm được hai bài'),
        ], state: AiMessageState.stopped),
      ]);
      expect(
        find.text('Mình đã tìm được hai bài', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Đã dừng'), findsOneWidget);
      // A plain Stop draws no error card, so no retry button either.
      expect(find.text('Thử lại'), findsNothing);
      expect(byEnabledState('Gửi', enabled: true), findsOneWidget);
      handle.dispose();
      await c.shot('06-stopped');
    });

    perShell('markdown, plain-text link and a [[t:ID]] track row', (
      tester,
      shell,
    ) async {
      final c = await openChat(
        tester,
        shell,
        library: {7: fakeTrack(7, title: 'Lạc trôi', artist: 'Sơn Tùng')},
      );
      await c.messages([
        _user(1, 'Cho mình vài bài'),
        _toolResult(
          2,
          'search_library',
          '{"total":1,"items":["7|Lạc trôi|Sơn Tùng|x|2017"]}',
        ),
        _answer(3, const [
          TextPart(
            'Đây là gợi ý của mình.\n\n'
            'Mình chọn **ba bài** hợp mood:\n\n'
            '- Chạy ngay đi\n'
            '- dùng `inline_code` ở đây\n'
            '- [một liên kết](http://example.com)\n\n'
            '[[t:7]]',
          ),
        ]),
      ]);
      expect(find.text('Đây là gợi ý của mình.', findRichText: true), findsOne);
      expect(find.textContaining('ba bài', findRichText: true), findsOne);
      expect(find.textContaining('Chạy ngay đi', findRichText: true), findsOne);
      expect(find.textContaining('inline_code', findRichText: true), findsOne);
      // A link stays plain text.
      expect(
        find.textContaining(
          '[một liên kết](http://example.com)',
          findRichText: true,
        ),
        findsOne,
      );
      // The id of a song the conversation saw is a row, not text.
      expect(find.text('Lạc trôi'), findsOneWidget);
      expect(find.text('Sơn Tùng'), findsOneWidget);
      expect(find.text('[[t:7]]', findRichText: true), findsNothing);
      await c.shot('07-markdown-track-row');
      if (c.isPhone) {
        await tester.longPress(find.text('Lạc trôi'));
        expect(c.tracks.calls, ['menu 7']);
        expect(byIconButton('Menu bài'), findsNothing);
      } else {
        await tester.tap(find.text('Lạc trôi'));
        await tester.pump();
        expect(c.tracks.calls, ['play 7']);
        await tester.tap(byIconButton('Menu bài'));
        await tester.pump();
        expect(c.tracks.calls, ['play 7', 'menu 7']);
      }
    });
  });

  group('tool cards', () {
    perShell('Đã làm: a finished change with its folded list', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      final call = writeCall('remove_from_queue', {
        'entryIds': [1, 2, 3, 4],
      });
      await c.messages([
        _user(1, 'Bỏ vài bài khỏi hàng đợi'),
        toolRow(
          2,
          state: AiMessageState.done,
          parts: [
            call,
            ToolResultPart(
              id: call.id,
              name: call.name,
              content: const [TextPart('{}')],
            ),
            DonePart(callId: call.id, removed: songsOf(3)),
          ],
        ),
      ]);
      expect(find.text('Đã làm: bỏ 3 bài khỏi hàng đợi'), findsOneWidget);
      expect(find.text('3 bài đã bỏ'), findsOneWidget);
      expect(find.text('Mở hàng đợi'), findsOneWidget);
      await c.shot('08-done');
    });

    perShell('confirm card: Cho phép / Từ chối answer the controller', (
      tester,
      shell,
    ) async {
      final c = await openChat(
        tester,
        shell,
        preview: ToolPreview(summary: 'Giống Lạc trôi', tracks: songsOf(6)),
      );
      await c.messages([
        _user(1, 'Tạo playlist giống Lạc trôi'),
        _confirmRow(),
      ]);
      expect(
        find.text('Tạo playlist “Giống Lạc trôi” · 6 bài'),
        findsOneWidget,
      );
      expect(find.text('Tạo playlist · cần bạn cho phép'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);
      expect(find.text('Cho phép'), findsOneWidget);
      await c.shot('09-confirm');
      await tester.tap(find.text('Cho phép'));
      await c.pump();
      expect(c.session.calls, contains('allow ${_createCall.id}'));
    });

    perShell('allowed and waiting: no buttons and not dimmed', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      await c.messages([
        _user(1, 'Tạo playlist giống Lạc trôi'),
        _confirmRow(
          state: AiMessageState.allowed,
          status: ConfirmStatus.allowed,
        ),
      ]);
      final title = find.text('Bạn đã cho phép · Tạo playlist');
      expect(title, findsOneWidget);
      expect(find.text('Cho phép'), findsNothing);
      expect(find.text('Từ chối'), findsNothing);
      // User decision 27/11: the waiting card is not drawn as finished.
      final dimmed = find.ancestor(
        of: title,
        matching: find.byWidgetPredicate(
          (w) =>
              (w is Opacity && w.opacity < 1) ||
              (w is AnimatedOpacity && w.opacity < 1),
          description: 'an Opacity below 1',
        ),
      );
      expect(dimmed, findsNothing);
      await c.shot('10-allowed-waiting');
    });

    perShell('denied, expired and skipped cards have no buttons', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      await c.messages([
        _user(1, 'Làm giúp mình'),
        _skippedRow(deniedByUserText, ConfirmStatus.denied),
        _skippedRow(expiredText, ConfirmStatus.expired),
        _skippedRow(stoppedByUserText, null),
      ]);
      expect(find.text('Đã từ chối'), findsOneWidget);
      expect(find.text('Đã hết hạn'), findsOneWidget);
      expect(
        find.text('Thẻ chờ quá 24 giờ. Muốn làm thì nhắn lại cho AI.'),
        findsOneWidget,
      );
      expect(find.text('Không chạy: bạn đã dừng'), findsOneWidget);
      expect(find.text('Cho phép'), findsNothing);
      await c.shot('11-denied-expired-skipped');
    });

    perShell('the 50-removal cap ends in the limit card, no retry', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      final call = writeCall('remove_from_queue', {
        'entryIds': [for (var i = 1; i <= 12; i++) i],
      });
      await c.messages([
        _user(1, 'Xoá hết hàng đợi'),
        toolRow(
          2,
          state: AiMessageState.error,
          parts: [
            call,
            errorResult(call, 'limit reached'),
            const ErrorPart(code: limitReachedCode, kind: 'invalidResponse'),
          ],
        ),
      ]);
      expect(
        find.text('AI đã đạt giới hạn thay đổi cho tin này'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mỗi tin chỉ được bỏ tối đa 50 bài'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsNothing);
      await c.shot('12-limit');
    });
  });

  group('composer', () {
    perShell('chips: suggested, attached, struck; send blocked while struck', (
      tester,
      shell,
    ) async {
      final handle = tester.ensureSemantics();
      final c = await openChat(tester, shell);
      final attachments = c.container.read(chatAttachmentsProvider.notifier);
      attachments
        ..setSuggestions(const [
          ChipPart(kind: ChipKind.album, ref: 'k', label: 'Blue'),
        ])
        ..attach(const ChipPart(kind: ChipKind.nowPlaying));
      await c.pump();
      expect(find.text('Bài đang phát'), findsOneWidget);
      expect(find.textContaining('Album: Blue'), findsOneWidget);
      await c.shot('13-chips-attached');

      // The tool group of the attached chip goes off: the chip is struck.
      c.container
          .read(fakeComposerSettingsProvider.notifier)
          .set(
            ComposerSettings(
              enabledGroups: AiToolGroup.values.toSet()
                ..remove(AiToolGroup.nowPlaying),
            ),
          );
      await c.pump();
      expect(
        find.textContaining('đang tắt nên thẻ này không gửi được'),
        findsOneWidget,
      );
      expect(byEnabledState('Gửi', enabled: false), findsOneWidget);
      await c.shot('14-chips-struck');
      await tester.tap(find.text('Bỏ thẻ'));
      await c.pump();
      expect(byEnabledState('Gửi', enabled: true), findsOneWidget);
      handle.dispose();
    });

    perShell('plugin and model pickers open', (tester, shell) async {
      final c = await openChat(
        tester,
        shell,
        plugins: [
          chatPlugin(id: chatPluginId),
          chatPlugin(id: 'p2', name: 'Gemini', readiness: const ChatNeedsKey()),
        ],
      );
      await tester.tap(byIconButton('Dịch vụ AI: Claude'));
      await tester.pumpAndSettle();
      expect(
        find.text('Áp dụng từ tin nhắn tiếp theo. Lịch sử giữ nguyên.'),
        findsOneWidget,
      );
      expect(find.text('Gemini'), findsOneWidget);
      expect(find.text('Cần API key'), findsOneWidget);
      expect(find.text('Thêm dịch vụ AI…'), findsOneWidget);
      await c.shot('15-plugin-picker');
      await tester.tap(find.text('Claude').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('m1'));
      await tester.pumpAndSettle();
      expect(find.text('Model 1'), findsOneWidget);
      expect(find.text('Model 2'), findsOneWidget);
      await c.shot('16-model-picker');
    });

    perShell('a composer notice keeps the draft and can be dismissed', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      c.container
          .read(composerDraftProvider.notifier)
          .set(const TextEditingValue(text: 'Dịch lời bài này'));
      c.container
          .read(composerSendNoticeProvider.notifier)
          .set(const NoticeSendFailed());
      await c.pump();
      expect(
        find.text('Chưa lưu được tin nhắn. Chữ vẫn ở đây; thử gửi lại.'),
        findsOneWidget,
      );
      expect(c.container.read(composerDraftProvider).text, 'Dịch lời bài này');
      await c.shot('17-composer-notice');
      await tester.tap(byIconButton('Đóng thông báo'));
      await c.pump();
      expect(find.textContaining('Chưa lưu được tin nhắn'), findsNothing);
    });
  });

  group('error cards', () {
    // One row per plugin error code the card maps (error_card_spec.dart).
    final rows =
        <
          ({
            String name,
            String code,
            String kind,
            String title,
            String? button,
          })
        >[
          (
            name: 'network',
            code: 'network',
            kind: 'server',
            title: 'Không kết nối được tới api.anthropic.com',
            button: 'Thử lại',
          ),
          (
            name: 'key',
            code: 'key',
            kind: 'auth',
            title: 'Claude không nhận API key',
            button: 'Mở cài đặt plugin',
          ),
          (
            name: 'quota',
            code: 'quota',
            kind: 'quota',
            title: 'Tài khoản Claude đã hết hạn mức',
            button: 'Thử lại',
          ),
          (
            name: 'config',
            code: 'config',
            kind: 'server',
            title: 'Cài đặt của Claude chưa đủ',
            button: 'Mở cài đặt plugin',
          ),
          (
            name: 'server',
            code: 'server',
            kind: 'server',
            title: 'Claude gặp lỗi',
            button: 'Thử lại',
          ),
          (
            name: 'host not allowed',
            code: 'host_not_allowed',
            kind: 'server',
            title: 'Plugin không được phép gọi api.anthropic.com',
            button: null,
          ),
          (
            name: 'blocked',
            code: 'blocked',
            kind: 'server',
            title: 'Model không trả lời yêu cầu này',
            button: 'Thử lại',
          ),
        ];
    for (final row in rows) {
      perShell('error code ${row.name}', (tester, shell) async {
        final c = await openChat(tester, shell);
        await c.messages([
          userRow(1),
          failedRow(2, code: row.code, kind: row.kind),
        ]);
        expect(find.text(row.title), findsOneWidget);
        if (row.button == null) {
          expect(find.text('Thử lại'), findsNothing);
        } else {
          expect(find.text(row.button!), findsOneWidget);
        }
        await c.shot('18-error-${row.code}');
      });
    }

    perShell('429 shows a countdown and no automatic retry', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      await c.messages([
        userRow(1),
        failedRow(
          2,
          code: 'rate_limit',
          kind: 'rateLimited',
          retryAt: chatNow.add(const Duration(seconds: 28)),
        ),
      ]);
      expect(find.text('Claude đang giới hạn số yêu cầu'), findsOneWidget);
      expect(find.text('Thử lại sau 28 giây'), findsOneWidget);
      expect(c.session.calls, isNot(contains('retry')));
      await c.shot('19-error-rate-limit');
    });
  });
}
