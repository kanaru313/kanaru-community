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
  List<ChipPart>? _sent;

  @override
  Widget build(BuildContext context) {
    final chips = ref.watch(
      chatSuggestionsProvider(AppLocalizations.of(context)),
    );
    if (_sent == null || !listEquals(_sent, chips)) {
      _sent = chips;
      // After the frame: a provider must not change while the tree builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(chatAttachmentsProvider.notifier).setSuggestions(chips);
        }
      });
    }
    return const SizedBox.shrink();
  }
}
