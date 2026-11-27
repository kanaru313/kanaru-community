import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/chat_messages_provider.dart';
import '../state/chat_view/chat_view_state.dart';
import '../state/chat_view/message_view.dart';
import 'assistant_message.dart';
import 'chat_card_slot.dart';
import 'chat_jump_button.dart';
import 'message_bubble.dart';
import 'tool_card.dart';
import 'track_row.dart';

final _log = Logger('ai.message_list');

/// How far from the oldest loaded message the next page is asked for.
const double _olderTrigger = 600;

/// The conversation's messages, oldest at the top, the newest at the bottom.
///
/// Built around a centre: the first message loaded (or the one the list was
/// scrolled to before the chat was rebuilt) sits at offset 0, older pages are
/// added above it and new text grows below it, so neither moves what the
/// reader looks at. Within about one screen of the end the list follows new
/// text; further up it keeps its place and shows the "Xuống cuối" button.
class ChatMessageList extends ConsumerStatefulWidget {
  const ChatMessageList({
    super.key,
    required this.conversationId,
    required this.messages,
  });

  final int conversationId;
  final ChatMessages messages;

  @override
  ConsumerState<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends ConsumerState<ChatMessageList> {
  final _controller = ScrollController();
  final _centerKey = GlobalKey();
  final _slots = <int, _SlotState>{};
  final _showJump = ValueNotifier<bool>(false);
  late int _centerId;
  bool _atBottom = true;
  bool _loadingOlder = false;
  double _lastMax = 0;

  List<ChatItem> _items = const [];
  Set<int> _known = const {};
  List<dynamic>? _derivedFrom;

  @override
  void initState() {
    super.initState();
    final messages = widget.messages.messages;
    final anchor = ref.read(chatScrollAnchorProvider);
    final restored = anchor != null && messages.any((m) => m.id == anchor);
    _centerId = restored ? anchor : messages.first.id;
    _atBottom = !restored;
    _showJump.value = restored;
  }

  @override
  void dispose() {
    _controller.dispose();
    _showJump.dispose();
    super.dispose();
  }

  void _derive() {
    final messages = widget.messages.messages;
    if (identical(_derivedFrom, messages)) return;
    _derivedFrom = messages;
    _items = chatItemsOf(messages);
    _known = knownTrackIds(messages);
  }

  bool _onMetrics(ScrollMetricsNotification n) {
    final max = n.metrics.maxScrollExtent;
    if (max != _lastMax) {
      _lastMax = max;
      // The newest text grew (or the first layout measured): stay at the end.
      if (_atBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_controller.hasClients || !_atBottom) return;
          final p = _controller.position;
          if (p.pixels != p.maxScrollExtent) p.jumpTo(p.maxScrollExtent);
        });
      }
    }
    return false;
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is! ScrollUpdateNotification && n is! ScrollEndNotification) {
      return false;
    }
    final m = n.metrics;
    _atBottom = m.maxScrollExtent - m.pixels <= m.viewportDimension;
    _showJump.value = !_atBottom;
    if (m.pixels - m.minScrollExtent < _olderTrigger) _loadOlder();
    if (n is ScrollEndNotification) _rememberPlace();
    return false;
  }

  void _loadOlder() {
    if (!widget.messages.hasMore || _loadingOlder) return;
    _loadingOlder = true;
    final notifier = ref.read(
      chatMessagesProvider(widget.conversationId).notifier,
    );
    unawaited(
      notifier
          .loadOlder()
          .catchError((Object e, StackTrace s) => _log.warning('older', e, s))
          .whenComplete(() => _loadingOlder = false),
    );
  }

  /// Saves the message at the top of the view (null at the end) so a rebuilt
  /// chat opens where the reader was.
  void _rememberPlace() {
    final anchor = ref.read(chatScrollAnchorProvider.notifier);
    if (_atBottom) {
      anchor.set(null);
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    int? best;
    double bestTop = double.infinity;
    for (final slot in _slots.values) {
      final r = slot.context.findRenderObject();
      if (r is! RenderBox || !r.attached) continue;
      final y = r.localToGlobal(Offset.zero).dy;
      // First message whose bottom edge is inside the view.
      if (y + r.size.height > top && y < bestTop) {
        bestTop = y;
        best = slot.messageId;
      }
    }
    anchor.set(best);
  }

  void _jumpToEnd() {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    _atBottom = true;
    _showJump.value = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      p.jumpTo(p.maxScrollExtent);
    } else {
      unawaited(
        p.animateTo(
          p.maxScrollExtent,
          duration: KMotion.normal,
          curve: KMotion.emphasized,
        ),
      );
    }
  }

  Widget _row(ChatItem item) {
    final id = item.message.id;
    final child = switch (item) {
      ChatUserItem() => _spaced(UserMessage(item: item)),
      ChatAssistantItem() => _spaced(AssistantMessage(item: item)),
      ChatToolItem() => ToolCard(message: item.message),
      ChatSwitchItem() => _spaced(_SwitchDivider(item: item)),
      ChatCardItem() => Builder(
        builder: (context) {
          final card = ref.read(chatCardBuilderProvider)(context, item.message);
          return card == null ? const SizedBox.shrink() : _spaced(card);
        },
      ),
    };
    return _Slot(key: ValueKey(id), messageId: id, owner: this, child: child);
  }

  Widget _spaced(Widget child) => Padding(
    padding: const EdgeInsets.only(top: KSpace.x3),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    _derive();
    final items = _items;
    var centre = items.indexWhere((i) => i.message.id >= _centerId);
    if (centre < 0) centre = items.length;
    final older = items.sublist(0, centre);
    final newer = items.sublist(centre);
    const side = EdgeInsets.symmetric(horizontal: KSpace.x4);
    return ChatKnownTracks(
      ids: _known,
      child: Stack(
        children: [
          NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                controller: _controller,
                center: _centerKey,
                slivers: [
                  // Before the centre index 0 is the message next to it.
                  SliverPadding(
                    padding: side.copyWith(top: KSpace.x3),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _row(older[older.length - 1 - i]),
                        childCount: older.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    key: _centerKey,
                    padding: side.copyWith(bottom: KSpace.x3),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _row(newer[i]),
                        childCount: newer.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            bottom: KSpace.x3,
            start: 0,
            end: 0,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _showJump,
                builder: (context, visible, _) =>
                    ChatJumpButton(visible: visible, onPressed: _jumpToEnd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Registers a row with the list so it can tell which message is on top.
class _Slot extends StatefulWidget {
  const _Slot({
    super.key,
    required this.messageId,
    required this.owner,
    required this.child,
  });

  final int messageId;
  final _ChatMessageListState owner;
  final Widget child;

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> {
  int get messageId => widget.messageId;

  @override
  void initState() {
    super.initState();
    widget.owner._slots[widget.messageId] = this;
  }

  @override
  void dispose() {
    if (widget.owner._slots[widget.messageId] == this) {
      widget.owner._slots.remove(widget.messageId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Từ đây dùng Gemini · gemini-2.5-flash", centred between two short rules.
class _SwitchDivider extends StatelessWidget {
  const _SwitchDivider({required this.item});

  final ChatSwitchItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final model = item.model;
    final label = model == null || model.isEmpty
        ? l10n.aiChatPluginSwitchNoModel(item.toName)
        : l10n.aiChatPluginSwitch(item.toName, model);
    final rule = SizedBox(
      width: KSpace.x6,
      child: Divider(height: 1, color: scheme.outlineVariant),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          rule,
          const SizedBox(width: KSpace.x2),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: KSpace.x2),
          rule,
        ],
      ),
    );
  }
}
