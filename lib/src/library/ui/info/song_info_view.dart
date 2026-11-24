import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../extension/state/extension_providers.dart';
import '../../../media/domain/track_info.dart';
import '../../../platform/state/file_manager_provider.dart';
import '../../domain/info/song_details.dart';
import '../../state/info/song_details_providers.dart';
import '../menus/link_rows.dart' show folderLocation;
import '../menus/menu_action_runner.dart';
import '../menus/menu_actions.dart';
import 'song_info_groups.dart';
import 'song_info_hero.dart';
import 'song_info_notice.dart';
import 'song_info_row_actions.dart';
import 'song_info_rows.dart';
import 'song_info_skeleton.dart';

/// Body of the song info route: loading bars, "gone", a read error or the
/// groups. The head of a box (cover, name) is [SongInfoHero] drawn by the
/// frame; on a page the hero is the first item here.
class SongInfoView extends ConsumerWidget {
  const SongInfoView({super.key, required this.info, required this.onOpen});

  final TrackInfo info;

  /// A link or "go to folder" was chosen: the opener closes the route and
  /// opens the library page at this location.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = KOverlayPageScope.maybeKindOf(context) == KOverlayKind.page;
    final async = ref.watch(songDetailsProvider(info.id));
    final Widget child;
    if (async.hasError && !async.hasValue) {
      child = _Message(
        icon: KIcons.warning,
        message: l10n.libraryInfoLoadFailed,
        page: page,
        back: false,
      );
    } else if (!async.hasValue) {
      child = const SongInfoSkeleton();
    } else if (async.value == null) {
      child = _Message(
        icon: KIcons.help,
        message: l10n.libraryNotFoundMessage,
        page: page,
        back: true,
      );
    } else {
      child = _Loaded(
        info: info,
        details: async.value!,
        page: page,
        onOpen: onOpen,
      );
    }
    return child;
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.message,
    required this.page,
    required this.back,
  });

  final IconData icon;
  final String message;
  final bool page;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = KEmpty(
      icon: icon,
      message: message,
      action: back
          ? KModalButton(
              label: l10n.libraryMenuBack,
              emphasis: KModalEmphasis.secondary,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
    );
    return page ? empty : SizedBox(height: 280, child: empty);
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.info,
    required this.details,
    required this.page,
    required this.onOpen,
  });

  final TrackInfo info;
  final SongDetails details;
  final bool page;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final showEmpty = ref.watch(songInfoShowEmptyProvider);
    final canReveal = ref.watch(fileManagerProvider).canReveal;
    final sections = ref.watch(extensionRegistryProvider).songDetailSections;
    final groups = buildSongInfoGroups(
      l10n,
      details,
      DateTime.now(),
      showEmpty: showEmpty,
      canReveal: canReveal,
      desktop: desktop,
    );
    final runner = MenuActionRunner(
      ProviderScope.containerOf(context, listen: false),
      context,
    );
    final path = details.path;
    final actions = SongInfoRowActions(
      openLink: (link) => onOpen(link.location),
      copied: (text) => showAppSnackBar(context, l10n.libraryInfoCopied(text)),
      copyPath: () {
        if (path != null) runner.run(MenuAction.copy(path));
      },
      goFolder: () => onOpen(folderLocation(details.folder)),
      reveal: () {
        if (path != null) runner.run(MenuAction.reveal(path));
      },
      toggleFavorite: (on) =>
          runner.run(MenuAction.favorite([details.id], on: on)),
    );
    final side = page ? KSpace.x4 : KSpace.x6;
    return ListView(
      padding: EdgeInsets.fromLTRB(side, KSpace.x2, side, KSpace.x6),
      children: [
        if (page) ...[
          SongInfoHero(info: info, details: details),
          const KGap(KSpace.x2),
        ],
        SongInfoNotice(details: details),
        for (final g in groups) ...[
          KInfoGroup(
            title: g.title,
            icon: g.icon,
            children: [
              for (final r in g.rows)
                SongInfoRow(
                  key: ValueKey(r.id),
                  spec: r,
                  trackId: details.id,
                  actions: actions,
                ),
            ],
          ),
          if (g.id == 'tags')
            for (final s in sections) s.build(context, details.id.value),
        ],
      ],
    );
  }
}
