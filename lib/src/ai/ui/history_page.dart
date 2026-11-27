import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/chat_providers.dart';
import '../state/chat_session.dart';
import '../state/chat_view/chat_view_state.dart';
import '../state/chat_view/history_view.dart';
import 'history_row.dart';

/// Key of the history page, which replaces the conversation while the history
/// flag of `chatViewProvider` is set.
const ValueKey<String> chatHistoryPageKey = ValueKey('chat history page');

/// Head of the history page, in place of the chat's head: back to the open
/// conversation, the title, the new-conversation button (it opens a new
/// conversation, the open one when still empty, and leaves the history), and
/// on the desktop panel ✕ ([onClose]) after it.
class ChatHistoryHeader extends ConsumerWidget {
  const ChatHistoryHeader({super.key, required this.style, this.onClose});

  /// Text style of the title; the panel and the phone page differ.
  final TextStyle? style;

  /// Closes the panel (✕); null on the phone page, which has no ✕ here. Its
  /// presence also marks the desktop panel, which shows keyboard hints.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: KLayout.minTarget + KSpace.x2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
        child: Row(
          children: [
            KIconButton(
              icon: KIcons.back,
              tooltip: onClose != null
                  ? l10n.aiChatHistoryBackPanel
                  : l10n.aiChatHistoryBackPage,
              onPressed: ref.read(chatViewProvider.notifier).closeHistory,
            ),
            const KGap(KSpace.x2),
            Expanded(
              child: Text(
                l10n.aiChatHistoryTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            KIconButton(
              icon: KIcons.compose,
              tooltip: onClose != null
                  ? '${l10n.aiChatNewTitle} (Ctrl+Shift+O)'
                  : l10n.aiChatNewTitle,
              semanticLabel: l10n.aiChatNewTitle,
              onPressed: () => unawaited(
                ref.read(chatViewProvider.notifier).startNewConversation(),
              ),
            ),
            if (onClose != null)
              KIconButton(
                icon: KIcons.close,
                tooltip: l10n.aiChatClosePanel,
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}

/// The list of past conversations: search, then the conversations in groups
/// (today, the past 7 days, older). Esc steps back to the open conversation;
/// the page takes focus so Esc reaches it.
class ChatHistoryPage extends ConsumerStatefulWidget {
  const ChatHistoryPage({super.key = chatHistoryPageKey});

  @override
  ConsumerState<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends ConsumerState<ChatHistoryPage>
    with WidgetsBindingObserver {
  final _search = TextEditingController();

  /// The conversation whose name is an input, if any.
  int? _renamingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// The calendar day the list was last built for; a build on another day
  /// regroups (no timer: a list left open is checked when it builds or when
  /// the app resumes).
  DateTime? _builtDay;

  /// Regroup when the app comes back: the day may have changed meanwhile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(chatHistorySectionsProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clock = ref.read(chatHistoryClockProvider)();
    final day = DateTime(clock.year, clock.month, clock.day);
    if (_builtDay != null && _builtDay != day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(chatHistorySectionsProvider);
      });
    }
    _builtDay = day;
    final query = ref.watch(chatHistoryQueryProvider).trim();
    final sections = ref.watch(chatHistorySectionsProvider).value;
    final openId = ref.watch(
      chatSessionProvider.select((s) => s.conversationId),
    );
    final plugins = ref.watch(chatPluginsProvider).value;
    final names = plugins == null
        ? null
        : {for (final p in plugins) p.installId: p.name};
    final items = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x4,
          KSpace.x1,
          KSpace.x4,
          KSpace.x2,
        ),
        child: KFilterField(
          controller: _search,
          hint: l10n.aiChatHistorySearch,
          persistent: true,
          onClose: () {},
          onChanged: ref.read(chatHistoryQueryProvider.notifier).set,
        ),
      ),
      if (sections != null && sections.isEmpty && query.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(KSpace.x6),
          child: Text(
            l10n.aiChatHistoryNoMatch(query),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final section in sections ?? const <HistorySection>[]) ...[
        _GroupHeading(_groupLabel(l10n, section.group)),
        for (final c in section.conversations)
          HistoryRow(
            key: historyRowKey(c.id),
            conversation: c,
            today: section.group == HistoryGroup.today,
            current: c.id == openId,
            pluginName: names?[c.installId],
            pluginRemoved:
                names != null &&
                c.installId != null &&
                !names.containsKey(c.installId),
            renaming: _renamingId == c.id,
            onRenameStart: () => setState(() => _renamingId = c.id),
            onRenameEnd: () {
              if (_renamingId == c.id) setState(() => _renamingId = null);
            },
          ),
      ],
    ];
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          return ref.read(chatViewProvider.notifier).back()
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
        return KeyEventResult.ignored;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: KSpace.x4),
        itemCount: items.length,
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  String _groupLabel(AppLocalizations l10n, HistoryGroup group) =>
      switch (group) {
        HistoryGroup.today => l10n.aiChatHistoryToday,
        HistoryGroup.week => l10n.aiChatHistoryWeek,
        HistoryGroup.older => l10n.aiChatHistoryOlder,
      };
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x3,
        KSpace.x4,
        KSpace.x1,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
