import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../../library/state/browse/song_list_providers.dart'
    show TrackRowLoader, trackRowLoaderProvider;
import '../domain/conversation/ai_message.dart';
import '../domain/loop/loop_state.dart';
import '../state/chat_session.dart';
import '../state/chat_view/message_view.dart';
import '../state/live_text_provider.dart';
import 'assistant_blocks.dart';
import 'markdown/chat_markdown_plain.dart';
import 'message_time.dart';
import 'track_row.dart';

final _log = Logger('ai.assistant_message');

/// An answer of the assistant: text on the page (no bubble), then either the
/// three dots (while it streams) or "Đã dừng" and the footer (time · model,
/// copy).
///
/// Only a message that is streaming watches [liveTextProvider]; a finished one
/// is built from its stored text, so a delta rebuilds one message and nothing
/// else in the list.
class AssistantMessage extends ConsumerWidget {
  const AssistantMessage({super.key, required this.item});

  final ChatAssistantItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = item.message;
    final streaming = message.state == AiMessageState.streaming;
    final stored = displayText(message);
    final String text;
    if (streaming) {
      text =
          ref.watch(liveTextProvider(message.id)) ?? message.liveText ?? stored;
    } else {
      text = stored;
    }
    final running =
        streaming &&
        ref.watch(chatSessionProvider.select((s) => s.turnState)) ==
            TurnState.streaming;
    return MessageHoverScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AssistantBlocks(text: text, streaming: streaming),
          if (running) const _Dots(),
          if (message.state == AiMessageState.stopped) const _Stopped(),
          if (!streaming) _Footer(message: message, text: text),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: KSpace.x1),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: KStreamingDots(
        label: AppLocalizations.of(context).aiChatAnswering,
      ),
    ),
  );
}

class _Stopped extends StatelessWidget {
  const _Stopped();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(KIcons.cancel, size: KIconSize.xs, color: color),
          const SizedBox(width: KSpace.x1),
          Text(
            AppLocalizations.of(context).aiChatStopped,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.message, required this.text});

  final AiMessage message;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final model = message.model;
    final known = ChatKnownTracks.of(context);
    // Read before the copy awaits: the footer may be gone by then.
    final loader = ref.read(trackRowLoaderProvider);
    return Row(
      children: [
        MessageTime(at: message.createdAt),
        if (model != null && model.isNotEmpty) ...[
          ExcludeSemantics(child: Text(' · ', style: style)),
          Flexible(
            child: Text(
              model,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
        MessageCopyButton(textBuilder: () => _plainText(loader, known)),
      ],
    );
  }
}

extension on _Footer {
  /// The answer as it reads on screen: song lines of this conversation become
  /// "title – artist", the rest of the markers are dropped.
  Future<String> _plainText(TrackRowLoader load, Set<int> known) async {
    final ids = <int>{
      for (final token in trackTokensOf(text))
        if (int.tryParse(token) case final id? when known.contains(id)) id,
    };
    final labels = <String, String>{};
    if (ids.isNotEmpty) {
      try {
        for (final info in await load([for (final id in ids) TrackId(id)])) {
          final artist = info.artist;
          labels['${info.id.value}'] = artist == null || artist.isEmpty
              ? info.title
              : '${info.title} – $artist';
        }
      } on Object catch (e, s) {
        // The songs are left out of the copy; the rest still copies.
        _log.warning('track lookup for copy failed', e, s);
      }
    }
    return plainAnswerText(text, trackLabel: (id) => labels[id]);
  }
}
