import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../domain/conversation/ai_conversation.dart';
import '../ai_conversation_store_provider.dart';
import '../chat_session.dart';
import 'chat_view_state.dart';

final _log = Logger('ai.chat_history');

/// The text typed in the history search. Gone with the history page, so the
/// next visit starts with the whole list.
class ChatHistoryQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String text) => state = text;
}

final chatHistoryQueryProvider =
    NotifierProvider.autoDispose<ChatHistoryQuery, String>(
      ChatHistoryQuery.new,
    );

/// How long typing and store changes settle before the list is read again;
/// tests shorten it.
final chatHistoryDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 250),
);

/// The search text the list is read with: [chatHistoryQueryProvider] after
/// it stopped changing for the debounce time (the first value is instant).
class ChatHistorySearch extends Notifier<String> {
  Timer? _timer;

  @override
  String build() {
    final delay = ref.watch(chatHistoryDebounceProvider);
    ref.onDispose(() => _timer?.cancel());
    ref.listen(chatHistoryQueryProvider, (_, next) {
      _timer?.cancel();
      final text = next.trim();
      if (text.isEmpty) {
        state = '';
        return;
      }
      _timer = Timer(delay, () => state = text);
    });
    return ref.read(chatHistoryQueryProvider).trim();
  }
}

final chatHistorySearchProvider =
    NotifierProvider.autoDispose<ChatHistorySearch, String>(
      ChatHistorySearch.new,
    );

/// The conversations the list shows, newest activity first: all of them, or
/// the ones whose title or text match the (debounced) search. Reloads when
/// the store reports a change, bursts of changes (a running turn writes
/// often) read once; the list already on screen stays until the new one is
/// read. The search is not repeated while the text and the store are
/// unchanged.
final chatHistoryConversationsProvider =
    FutureProvider.autoDispose<List<AiConversation>>((ref) {
      final query = ref.watch(chatHistorySearchProvider);
      final store = ref.watch(aiConversationStoreProvider);
      final delay = ref.watch(chatHistoryDebounceProvider);
      Timer? settle;
      final sub = store.changes.listen((_) {
        settle?.cancel();
        settle = Timer(delay, ref.invalidateSelf);
      });
      ref.onDispose(() {
        settle?.cancel();
        unawaited(sub.cancel());
      });
      return query.isEmpty ? store.list() : store.search(query);
    });

/// What "today" is for the grouping; tests replace it.
final chatHistoryClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

enum HistoryGroup { today, week, older }

/// One heading of the list with its conversations, in the order read.
class HistorySection {
  const HistorySection(this.group, this.conversations);

  final HistoryGroup group;
  final List<AiConversation> conversations;
}

/// Splits [conversations] (kept in their order) by the local calendar day of
/// their last message against [now]: today, one to seven days before today,
/// older. A day is a calendar day, not 24 hours, so the groups change at
/// midnight. Empty groups are left out.
List<HistorySection> groupHistory(
  List<AiConversation> conversations,
  DateTime now,
) {
  final today = _day(now);
  final byGroup = {for (final g in HistoryGroup.values) g: <AiConversation>[]};
  for (final c in conversations) {
    final days = today.difference(_day(c.lastMessageAt)).inDays;
    final group = days <= 0
        ? HistoryGroup.today
        : days <= 7
        ? HistoryGroup.week
        : HistoryGroup.older;
    byGroup[group]!.add(c);
  }
  return [
    for (final g in HistoryGroup.values)
      if (byGroup[g]!.isNotEmpty) HistorySection(g, byGroup[g]!),
  ];
}

/// The local date as a UTC midnight, so two dates differ by whole days even
/// across a daylight-saving change.
DateTime _day(DateTime at) {
  final t = at.toLocal();
  return DateTime.utc(t.year, t.month, t.day);
}

/// The list, grouped. Loading until the first read; the list stays while it
/// reloads.
final chatHistorySectionsProvider =
    Provider.autoDispose<AsyncValue<List<HistorySection>>>((ref) {
      final now = ref.watch(chatHistoryClockProvider)();
      // A list left open past midnight regroups: rebuild at the next local
      // midnight.
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final timer = Timer(midnight.difference(now), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      return ref
          .watch(chatHistoryConversationsProvider)
          .whenData((list) => groupHistory(list, now));
    });

/// What the history rows do. The state is the ids whose delete is running:
/// their rows show busy and ignore taps.
class ChatHistoryActions extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  /// Deletes conversation [id]: its turn stops first and, when it was the
  /// open one, the controller opens a new empty conversation in the same
  /// call. A second call for the same id while it runs does nothing. True
  /// when this call deleted it.
  Future<bool> delete(int id) async {
    if (state.contains(id)) return false;
    state = {...state, id};
    try {
      return await ref.read(chatViewProvider.notifier).deleteConversation(id);
    } finally {
      state = {...state}..remove(id);
    }
  }

  /// Opens conversation [id] and leaves the history for it. The controller
  /// stops a turn that is running in the open one; a conversation that no
  /// longer exists keeps the list on screen (it reloads without it).
  Future<void> open(int id) async {
    if (state.contains(id)) return;
    try {
      final opened = await ref.read(chatSessionProvider.notifier).open(id);
      if (opened) ref.read(chatViewProvider.notifier).closeHistory();
    } on Object catch (e, s) {
      _log.warning('opening a conversation failed: ${e.runtimeType}', e, s);
    }
  }

  /// Saves a new name for [conversation]; a blank or unchanged name changes
  /// nothing.
  Future<void> rename(AiConversation conversation, String text) async {
    final name = text.trim();
    if (name.isEmpty || name == conversation.title.trim()) return;
    try {
      await ref
          .read(chatSessionProvider.notifier)
          .rename(conversation.id, name);
    } on Object catch (e, s) {
      _log.warning('rename failed: ${e.runtimeType}', e, s);
    }
  }
}

final chatHistoryActionsProvider =
    NotifierProvider<ChatHistoryActions, Set<int>>(ChatHistoryActions.new);
