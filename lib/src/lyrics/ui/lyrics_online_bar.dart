import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../data/online/online_lyrics_commands.dart';
import '../data/online/store_result.dart';
import '../state/online/online_commands_provider.dart';
import 'lyrics_keep_notice.dart';
import 'online/online_row_info.dart';

final _log = Logger('lyrics_online_bar');

/// The bar under "Lời cho bài này" when there is something to do with the
/// online copy that shows: an automatically found one can be kept or refused
/// ("Tự tìm thấy trên LRCLIB · Giữ để lần sau không tìm lại"), a kept one
/// refused. Empty (nothing drawn) in every other case.
///
/// Each button closes the modal through [close], then writes. [close] returns
/// false when the modal is already closing: nothing is written then, so a
/// double tap writes once. The command is called in the same turn as the
/// close, while the modal still watches the track's lyrics: the command reads
/// what the track shows at that moment.
class LyricsOnlineBar extends ConsumerWidget {
  const LyricsOnlineBar({
    super.key,
    required this.trackId,
    required this.info,
    required this.close,
  });

  final TrackId trackId;
  final OnlineRowInfo? info;
  final bool Function() close;

  /// Closes the modal, runs [command], then tells the user how it went:
  /// [done] on success, the failed notice when the write was refused or threw.
  void _write(
    BuildContext context,
    WidgetRef ref,
    Future<Object?> Function(OnlineLyricsCommands commands) command,
    void Function(LyricsNotices notices) done,
  ) {
    final commands = ref.read(onlineLyricsCommandsProvider);
    final notices = LyricsNotices.of(context);
    if (!close()) return;
    unawaited(
      command(commands)
          .then((result) {
            // A refused write (the track is gone, no text) is a result, not
            // an error: say so in the log and to the user.
            if (result == StoreResult.notStored) {
              _log.warning('online lyrics copy was not stored');
              notices.failed();
            } else {
              done(notices);
            }
          })
          .catchError((Object error, StackTrace stack) {
            _log.warning('online lyrics write failed', error, stack);
            notices.failed();
          }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = this.info;
    if (info == null || !info.selected) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final auto = info.autoShown;
    final title = auto
        ? l10n.lyricsBarAutoTitle(info.providerName)
        : l10n.lyricsBarKeptTitle;
    final sub = auto ? l10n.lyricsBarAutoSub : l10n.lyricsBarKeptSub;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: text.titleSmall?.copyWith(color: scheme.onSurface)),
        Text(
          sub,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
    final buttons = [
      TextButton(
        onPressed: () => _write(
          context,
          ref,
          (c) => c.reject(trackId),
          auto ? (n) => n.refusedAuto() : (n) => n.refusedKept(),
        ),
        child: Text(l10n.lyricsBarReject),
      ),
      if (auto)
        FilledButton.tonal(
          onPressed: () => _write(
            context,
            ref,
            (c) => c.keepAuto(trackId),
            (n) => n.kept(info.providerName),
          ),
          child: Text(l10n.lyricsBarKeep),
        ),
    ];
    return Semantics(
      container: true,
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x3,
            KSpace.x4,
            KSpace.x4,
          ),
          // The buttons sit beside the words when both fit on one line, else
          // under them; a label never wraps (the buttons wrap as a group
          // first), and nothing overflows at large text.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KSpace.x3,
            runSpacing: KSpace.x2,
            children: [
              words,
              Wrap(
                spacing: KSpace.x2,
                runSpacing: KSpace.x1,
                children: buttons,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
