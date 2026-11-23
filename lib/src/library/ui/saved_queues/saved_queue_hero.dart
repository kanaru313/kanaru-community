import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_models.dart';
import '../browse/play_shuffle_buttons.dart';
import '../menus/more_button.dart';
import '../playlist_common/playlist_cover.dart';
import 'saved_queue_labels.dart';
import 'saved_queue_menu.dart';
import 'saved_queue_play.dart';

/// Top of a saved queue's page, the playlist hero without a description: the
/// framed automatic cover, the time it was saved, `N songs · length`,
/// `From …` and `[▶ Play] [shuffle] [⋮]`. Play and shuffle are off when
/// nothing in the queue can play, and while one press is being served.
class SavedQueueHero extends ConsumerStatefulWidget {
  const SavedQueueHero({super.key, required this.detail, required this.name});

  final PlaylistDetail detail;

  /// The queue's name (the time it was saved), worded by the page.
  final String name;

  @override
  ConsumerState<SavedQueueHero> createState() => _SavedQueueHeroState();
}

class _SavedQueueHeroState extends ConsumerState<SavedQueueHero> {
  /// A Play or shuffle press is being served: further presses are ignored.
  bool _serving = false;

  Future<void> _play({required bool shuffle}) async {
    if (_serving) return;
    setState(() => _serving = true);
    try {
      await playSavedQueue(
        context,
        widget.detail.summary.uid,
        shuffle: shuffle,
      );
    } finally {
      if (mounted) setState(() => _serving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = widget.detail.summary;
    final info = summary.savedQueue;
    final enabled =
        savedQueuePlayableIds(widget.detail).isNotEmpty && !_serving;
    return KDetailHero(
      framedCover: true,
      coverBuilder: (context, side, radius) => PlaylistCover(
        uid: summary.uid,
        autoCoverKeys: summary.autoCoverKeys,
        dimension: side,
        radius: radius,
      ),
      title: widget.name,
      line2: KDetailLine(text: savedQueueStatsLine(l10n, summary)),
      line3: info == null ? null : savedQueueSourceLine(l10n, info),
      actions: PlayShuffleButtons(
        compact: false,
        labelled: true,
        playLabel: l10n.libraryPlay,
        onPlay: enabled ? () => unawaited(_play(shuffle: false)) : null,
        onShuffle: enabled ? () => unawaited(_play(shuffle: true)) : null,
        trailing: [
          LibraryMoreButton(
            large: true,
            onPressed: ({required viaKeyboard}) => unawaited(
              openSavedQueueMenu(
                context,
                summary.uid,
                pageRoute: ModalRoute.of(context),
                viaKeyboard: viaKeyboard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
