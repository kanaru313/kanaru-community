import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/conversation/parts.dart';
import '../state/chat_view/message_view.dart';
import 'message_time.dart';

/// A message of the user: the bubble on the right, the chips it was sent with
/// under it, and the footer (time, copy).
class UserMessage extends StatelessWidget {
  const UserMessage({super.key, required this.item});

  final ChatUserItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = messageText(item.message);
    final chips = item.message.parts.whereType<ChipPart>().toList();
    return MessageHoverScope(
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FractionallySizedBox(
          widthFactor: 0.86,
          alignment: AlignmentDirectional.centerEnd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(20),
                    topEnd: Radius.circular(20),
                    bottomStart: Radius.circular(20),
                    bottomEnd: Radius.circular(6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KSpace.x3 + 2,
                    vertical: KSpace.x2 + 2,
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: scheme.onPrimaryContainer),
                  ),
                ),
              ),
              if (chips.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: KSpace.x1),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: KSpace.x1,
                    runSpacing: KSpace.x1,
                    children: [for (final c in chips) _SentChip(chip: c)],
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MessageTime(at: item.message.createdAt),
                  MessageCopyButton(text: text),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _chipIcon(ChipKind kind) => switch (kind) {
  ChipKind.nowPlaying || ChipKind.song || ChipKind.songs => KIcons.songs,
  ChipKind.album => KIcons.albums,
  ChipKind.artist => KIcons.artists,
  ChipKind.genre => KIcons.genres,
  ChipKind.language => KIcons.languages,
  ChipKind.playlist => KIcons.playlists,
};

/// A chip the message was sent with: small, tonal, not interactive.
class _SentChip extends StatelessWidget {
  const _SentChip({required this.chip});

  final ChipPart chip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = chip.label ?? chip.tracks.firstOrNull?.title ?? '';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: KRadius.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x2,
          vertical: KSpace.x1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _chipIcon(chip.kind),
              size: KIconSize.xs,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: KSpace.x1),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
