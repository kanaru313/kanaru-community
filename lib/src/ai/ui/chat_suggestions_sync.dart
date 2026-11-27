import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/conversation/parts.dart';
import '../state/chat_attachments.dart';
import '../state/chat_view/page_suggestions.dart';

/// Keeps the composer's suggested chips (the playing song, the selection, the
/// page under the chat) in step with what is on screen. Draws nothing; it
/// lives as long as the chat does.
class ChatSuggestionsSync extends ConsumerStatefulWidget {
  const ChatSuggestionsSync({super.key});

  @override
  ConsumerState<ChatSuggestionsSync> createState() =>
      _ChatSuggestionsSyncState();
}

class _ChatSuggestionsSyncState extends ConsumerState<ChatSuggestionsSync> {
  ProviderSubscription<List<ChipPart>>? _subscription;
  Locale? _locale;
  List<ChipPart>? _last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    if (_subscription != null && locale == _locale) return;
    _locale = locale;
    _subscription?.close();
    // Later changes arrive as provider events, never from a build. The first
    // value waits for the end of the frame: a provider must not change while
    // the tree builds.
    _subscription = ref.listenManual(
      chatSuggestionsProvider(l10n),
      (_, chips) => _push(chips),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _push(ref.read(chatSuggestionsProvider(l10n)));
    });
  }

  void _push(List<ChipPart> chips) {
    if (listEquals(_last, chips)) return;
    _last = chips;
    ref.read(chatAttachmentsProvider.notifier).setSuggestions(chips);
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
