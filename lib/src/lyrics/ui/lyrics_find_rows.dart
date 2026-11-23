import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'online/online_source_providers.dart';
import 'online/open_lyrics_plugin_store.dart';

/// The rows after the divider of "Lời cho bài này": "Tìm lời trực tuyến…" (or
/// "Thêm nguồn lời trực tuyến" without a lyrics plugin), then the two
/// features that are not built yet (dimmed, inert, "Sắp có").
///
/// [close] is the modal's guarded close. [onFindOnline] is what the search
/// row does; null leaves the row dimmed with "Sắp có" (nothing to open yet).
class LyricsFindRows extends StatelessWidget {
  const LyricsFindRows({super.key, required this.close, this.onFindOnline});

  final bool Function() close;
  final VoidCallback? onFindOnline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // KListRow has no plain variant yet and fills with surfaceContainerLow,
    // which shows as a box on the dialog surface; these rows must read as
    // plain rows.
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme
            .copyWith(surfaceContainerLow: Colors.transparent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FindOnlineRow(close: close, onFindOnline: onFindOnline),
          _SoonRow(
            icon: KIcons.ai,
            title: l10n.lyricsFromAudio,
            subtitle: l10n.lyricsFromAudioSub,
          ),
          _SoonRow(icon: KIcons.fileExport, title: l10n.lyricsSaveLyrics),
        ],
      ),
    );
  }
}

class _FindOnlineRow extends ConsumerWidget {
  const _FindOnlineRow({required this.close, required this.onFindOnline});

  final bool Function() close;
  final VoidCallback? onFindOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final counts = ref.watch(onlineSourceCountsProvider);
    final chevron = Icon(
      KIcons.chevronRight,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    if (counts.loaded && counts.installed == 0) {
      return KListRow(
        leading: const Icon(KIcons.extension),
        title: Text(l10n.lyricsAddSource),
        subtitle: Text(l10n.lyricsAddSourceSub),
        trailing: chevron,
        onTap: () {
          if (!close()) return;
          openLyricsPluginStore(context, ref);
        },
      );
    }
    final subtitle = !counts.loaded
        ? null
        : counts.enabled == 0
        ? l10n.lyricsFindOnlineSubAllOff(counts.disabled)
        : l10n.lyricsFindOnlineSub(counts.enabled, counts.disabled);
    return KListRow(
      enabled: onFindOnline != null,
      leading: const Icon(KIcons.online),
      title: Text(l10n.lyricsFindOnline),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: onFindOnline == null ? const _SoonMark() : chevron,
      onTap: onFindOnline,
    );
  }
}

/// A feature that is not built yet: dimmed, never tappable, with its marker.
class _SoonRow extends StatelessWidget {
  const _SoonRow({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return KListRow(
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const _SoonMark(),
    );
  }
}

class _SoonMark extends StatelessWidget {
  const _SoonMark();

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).appComingSoon,
    style: Theme.of(context).textTheme.labelMedium,
  );
}
