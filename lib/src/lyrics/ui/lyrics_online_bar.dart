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

  void _write(
    WidgetRef ref,
    Future<Object?> Function(OnlineLyricsCommands commands) command,
  ) {
    final commands = ref.read(onlineLyricsCommandsProvider);
    if (!close()) return;
    unawaited(
      command(commands)
          .then((result) {
            // A refused write (the track is gone, no text) is a result, not
            // an error: say so in the log instead of dropping it.
            if (result == StoreResult.notStored) {
              _log.warning('online lyrics copy was not stored');
            }
          })
          .catchError((Object error, StackTrace stack) {
            _log.warning('online lyrics write failed', error, stack);
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
        onPressed: () => _write(ref, (c) => c.reject(trackId)),
        child: Text(l10n.lyricsBarReject),
      ),
      if (auto)
        FilledButton.tonal(
          onPressed: () => _write(ref, (c) => c.keepAuto(trackId)),
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
          child: Row(
            spacing: KSpace.x2,
            // Every child may shrink, so the row never overflows: the words wrap
            // and a button label wraps at large text or on a narrow sheet.
            children: [
              Expanded(flex: 3, child: words),
              for (final b in buttons) Flexible(flex: 2, child: b),
            ],
          ),
        ),
      ),
    );
  }
}
