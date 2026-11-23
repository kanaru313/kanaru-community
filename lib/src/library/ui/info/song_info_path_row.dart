import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import 'song_info_row_actions.dart';
import 'song_info_spec.dart';

/// The file path row: the path (struck through and flagged when the file is
/// gone) with copy, go-to-folder and show-in-file-manager buttons. On the
/// desktop shell the buttons sit at the end of the row; on touch shells they
/// get a row of their own under the path, aligned to the end.
class SongInfoPathRow extends StatelessWidget {
  const SongInfoPathRow({super.key, required this.spec, required this.actions});

  final InfoRowSpec spec;
  final SongInfoRowActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final path = spec.value;
    if (path == null) {
      return KInfoRow(label: spec.label, unknownText: l10n.libraryInfoUnknown);
    }
    final theme = Theme.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final gone = spec.missing;
    var style =
        (desktop ? theme.textTheme.bodyMedium : theme.textTheme.bodySmall)
            ?.copyWith(fontWeight: FontWeight.w500);
    if (gone) {
      style = style?.copyWith(
        color: theme.colorScheme.error,
        decoration: TextDecoration.lineThrough,
      );
    }
    Widget button(String tip, IconData icon, VoidCallback? tap) => KIconButton(
      tooltip: tip,
      icon: icon,
      size: KIconSize.sm,
      onPressed: tap,
    );
    final buttons = [
      button(l10n.libraryMenuCopyPath, KIcons.copy, actions.copyPath),
      button(
        l10n.libraryMenuGoFolder,
        KIcons.folders,
        gone ? null : actions.goFolder,
      ),
      if (spec.canReveal)
        button(
          l10n.libraryMenuReveal,
          KIcons.folderOpen,
          gone ? null : actions.reveal,
        ),
    ];
    return KInfoRow(
      label: spec.label,
      trailing: desktop
          ? Row(mainAxisSize: MainAxisSize.min, children: buttons)
          : null,
      valueWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          desktop
              ? SelectableText(path, style: style)
              : Text(path, style: style),
          if (gone)
            Padding(
              padding: const EdgeInsets.only(top: KSpace.x1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    KIcons.warning,
                    size: KIconSize.xs,
                    color: theme.colorScheme.error,
                  ),
                  const KGap(KSpace.x1),
                  Flexible(
                    child: Text(
                      l10n.libraryInfoMissingTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!desktop)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
            ),
        ],
      ),
    );
  }
}
