import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../storage/domain/m3u/m3u_limits.dart';
import '../../../storage/domain/m3u/m3u_text.dart';
import '../../data/m3u/m3u_results.dart';

/// Most lines listed under one group; the rest is counted.
const m3uReportLinesPerGroup = 5;

/// Longest line text shown, in graphemes.
const m3uReportLineMaxLength = 300;

/// Shows the import report on [context] (a root context: the page that
/// started the import may be gone). True when the user chose "Open playlist".
Future<bool> showM3uImportReport(
  BuildContext context,
  M3uImportResult result,
) async {
  final open = await showKDialog<bool>(
    context,
    builder: (_) => M3uImportReportDialog(result: result),
  );
  return open ?? false;
}

/// "Playlist imported": what was added and why some lines were not. Groups:
/// songs not in the library yet; unusable lines (not found, not music,
/// outside the music folders); lines the scan skips; relative lines with no
/// base folder. Each group's text says why (no help icon). Empty groups are
/// not drawn. Pops `true` for "Open playlist", `false` for "Close".
class M3uImportReportDialog extends StatelessWidget {
  const M3uImportReportDialog({super.key, required this.result});

  final M3uImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final unusable = _linesOf(const {
      M3uProblemKind.unresolved,
      M3uProblemKind.outsideFolders,
    });
    final skipped = _linesOf(const {M3uProblemKind.notScanned});
    final noBase = _linesOf(const {M3uProblemKind.noBaseFolder});
    return AlertDialog(
      title: Text(l10n.playlistM3uReportTitle),
      content: SingleChildScrollView(
        child: SelectionArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.playlistM3uReportSummary(
                  result.added,
                  result.totalLines,
                  result.fileName,
                  result.name,
                ),
                style: text.bodyMedium,
              ),
              if (result.notInLibrary > 0)
                _Group(
                  icon: KIcons.musicOff,
                  text: l10n.playlistM3uReportNotInLibrary(result.notInLibrary),
                  lines: const [],
                ),
              if (unusable.isNotEmpty)
                _Group(
                  icon: KIcons.linkOff,
                  text: l10n.playlistM3uReportUnresolved(unusable.length),
                  lines: unusable,
                ),
              if (skipped.isNotEmpty)
                _Group(
                  icon: KIcons.hideFromLibrary,
                  text: l10n.playlistM3uReportSkipped(skipped.length),
                  lines: skipped,
                ),
              if (noBase.isNotEmpty)
                _Group(
                  icon: KIcons.folderOff,
                  text: l10n.playlistM3uReportNoBase(noBase.length),
                  lines: noBase,
                ),
              if (result.truncated) ...[
                const KGap(KSpace.x3),
                Text(
                  l10n.m3uReportTruncated(m3uMaxPathLines),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.playlistClose),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.playlistM3uOpenPlaylist),
        ),
      ],
    );
  }

  List<M3uProblemLine> _linesOf(Set<M3uProblemKind> kinds) => [
    for (final p in result.problems)
      if (kinds.contains(p.kind)) p,
  ];
}

class _Group extends StatelessWidget {
  const _Group({required this.icon, required this.text, required this.lines});

  final IconData icon;
  final String text;
  final List<M3uProblemLine> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final shown = lines.take(m3uReportLinesPerGroup);
    final rest = lines.length - m3uReportLinesPerGroup;
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: KIconSize.sm, color: muted),
          const KGap(KSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyMedium),
                for (final line in shown)
                  Padding(
                    padding: const EdgeInsets.only(top: KSpace.x1),
                    child: Text(
                      l10n.playlistM3uReportLine(
                        line.line,
                        cleanReportLine(line.text),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                if (rest > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: KSpace.x1),
                    child: Text(
                      l10n.playlistM3uReportMore(rest),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [raw] as safe display text: control, direction and separator characters
/// shown as spaces (a line from a file must not hide or reorder what it says),
/// cut to [m3uReportLineMaxLength] graphemes with an ellipsis.
String cleanReportLine(String raw) {
  final clean = raw.replaceAll(m3uUnsafeTextChars, ' ').trim();
  final chars = clean.characters;
  if (chars.length <= m3uReportLineMaxLength) return clean;
  return '${chars.take(m3uReportLineMaxLength)}…';
}
