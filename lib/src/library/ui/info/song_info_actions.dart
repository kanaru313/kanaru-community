import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../state/info/song_details_providers.dart';
import 'song_info_groups.dart';

/// The eye of the info header: shows or hides the fields that have no value,
/// with the number of hidden ones on a badge. Off and dimmed while nothing
/// is empty; the choice is remembered.
class SongInfoEyeButton extends ConsumerWidget {
  const SongInfoEyeButton({super.key, required this.id});

  final TrackId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(songInfoShowEmptyProvider);
    final details = ref.watch(songDetailsProvider(id)).value;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final count = details == null
        ? 0
        : songInfoEmptyCount(l10n, details, DateTime.now(), desktop: desktop);
    final usable = details != null && (on || count > 0);
    return KInfoToggleButton(
      on: on,
      onChanged: usable
          ? (v) => ref.read(songInfoShowEmptyProvider.notifier).set(v)
          : null,
      icon: KIcons.eye,
      onIcon: KIcons.eyeOff,
      tooltip: l10n.libraryInfoShowEmpty(count),
      onTooltip: l10n.libraryInfoHideEmpty,
      disabledTooltip: l10n.libraryInfoNoEmpty,
      badgeCount: count,
      badgeLabel: l10n.libraryInfoEmptyBadge(count),
    );
  }
}

/// ⋮ of a page opened without a menu below: opens the song menu over it.
class SongInfoMoreButton extends StatelessWidget {
  const SongInfoMoreButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => KIconButton(
    tooltip: AppLocalizations.of(context).libraryInfoMore,
    icon: KIcons.moreVert,
    onPressed: onPressed,
  );
}
