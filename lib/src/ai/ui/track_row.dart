import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/cover_files.dart';
import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../../playback/state/track_info_providers.dart';
import '../../playback/ui/track_cover.dart';
import 'track_actions.dart';

final _log = Logger('ai.track_row');

/// The track ids a conversation has seen (tool results, changes, chips). A
/// `[[t:ID]]` line is a song row only for one of them.
class ChatKnownTracks extends InheritedWidget {
  const ChatKnownTracks({super.key, required this.ids, required super.child});

  final Set<int> ids;

  static Set<int> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatKnownTracks>()?.ids ??
      const {};

  @override
  bool updateShouldNotify(ChatKnownTracks old) => !identical(old.ids, ids);
}

/// Height of the song row's cover.
const double chatTrackCover = 36;

/// A `[[t:ID]]` line of an answer. An id the conversation never saw, a song
/// that is gone or an id that is not a number stays the text as typed.
class ChatTrackRow extends ConsumerWidget {
  const ChatTrackRow({super.key, required this.id, this.style});

  /// The raw token between `[[t:` and `]]`.
  final String id;

  /// Style of the fallback text.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final literal = Text('[[t:$id]]', style: style);
    final number = int.tryParse(id);
    if (number == null || !ChatKnownTracks.of(context).contains(number)) {
      return literal;
    }
    final info = ref.watch(trackInfoProvider(TrackId(number)));
    return info.when(
      data: (t) => t == null ? literal : _Row(info: t),
      // Same height as the row, so the answer does not jump when it loads.
      loading: () => const SizedBox(height: chatTrackCover + KSpace.x3),
      error: (_, _) => literal,
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.info});

  final TrackInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final actions = ref.read(chatTrackActionsProvider);

    void menu({required bool viaKeyboard}) => unawaited(
      actions
          .openMenu(context, info, viaKeyboard: viaKeyboard)
          .catchError((Object e, StackTrace s) => _log.warning('menu', e, s)),
    );

    final artist = info.artist ?? '';
    return KContextRegion(
      onOpen: (at) => menu(viaKeyboard: at == null),
      child: Material(
        color: KRowColors.fill(Theme.of(context).brightness),
        borderRadius: KRadius.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => unawaited(
            actions
                .play(info.id)
                .catchError(
                  (Object e, StackTrace s) => _log.warning('play', e, s),
                ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KSpace.x2,
              vertical: KSpace.x1 + 2,
            ),
            child: Row(
              children: [
                TrackCover(
                  coverKey: info.coverKey,
                  seed: info.coverSeed,
                  size: CoverSize.thumb,
                  dimension: chatTrackCover,
                  radius: KRadius.xs,
                ),
                const SizedBox(width: KSpace.x3 - 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (artist.isNotEmpty)
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Mobile has no ⋮: a long press opens the menu.
                if (desktop)
                  KMoreButton(tooltip: l10n.aiChatTrackMenu, onPressed: menu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
