import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/scan/media_index_refresh.dart';
import '../../../platform/domain/local_audio_catalog.dart';

/// The run id below which a refresh result is older than the moment a surface
/// (the folder sheet, the first-run card) was shown. A run that is running at
/// that moment counts as seen: its end happens while the surface is shown.
int refreshSeenFrom(IndexRefreshState state) => switch (state) {
  IndexRefreshRunning(:final runId) => runId - 1,
  _ => state.runId,
};

/// The finished run in [state] when the surface saw it, else null. A result
/// that lives on from an earlier visit must never show as news.
IndexRefreshFinished? seenRefreshResult(
  IndexRefreshState state,
  int seenFrom,
) => state is IndexRefreshFinished && state.runId > seenFrom ? state : null;

/// This Android cannot index on request (a device fact, not a stale result):
/// every rescan entry is hidden once a run reported it.
bool refreshUnsupported(IndexRefreshState state) =>
    state is IndexRefreshFinished &&
    state.outcome == MediaIndexRefresh.unsupported;

extension IndexRefreshFinishedX on IndexRefreshFinished {
  /// The system looked (it may still be working after a timeout), so the
  /// lists were read again.
  bool get looked =>
      outcome == MediaIndexRefresh.done ||
      outcome == MediaIndexRefresh.timedOut;

  bool get failed => outcome == MediaIndexRefresh.failed;
}

/// A state of the folder sheet that replaces the list: hero icon, title and
/// the given lines or buttons, centred.
class FolderSheetFrame extends StatelessWidget {
  const FolderSheetFrame({
    super.key,
    required this.icon,
    required this.title,
    this.isError = false,
    this.children = const [],
  });

  final IconData icon;
  final Widget title;

  /// Error tint for the icon.
  final bool isError;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: KIconSize.hero,
              color: isError ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
          const KGap(KSpace.x2),
          DefaultTextStyle.merge(
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            textAlign: TextAlign.center,
            child: title,
          ),
          for (final child in children) ...[const KGap(KSpace.x2), child],
        ],
      ),
    );
  }
}

/// Body text of a [FolderSheetFrame].
class FolderSheetBody extends StatelessWidget {
  const FolderSheetBody(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

/// The index is being read for the first time (or again after a retry).
class FolderSheetLoading extends StatelessWidget {
  const FolderSheetLoading({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: KSpace.x6,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const KGap(KSpace.x2),
        FolderSheetBody(label),
      ],
    ),
  );
}

/// Android's index holds no music (before a rescan).
class FolderSheetNoMusic extends StatelessWidget {
  const FolderSheetNoMusic({super.key, required this.onRescan});

  /// Null hides the button (this Android cannot rescan).
  final VoidCallback? onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FolderSheetFrame(
      icon: KIcons.search,
      title: Text(l10n.scanSetupNoMusicTitle),
      children: [
        FolderSheetBody(l10n.scanSetupNoMusicBody),
        if (onRescan != null)
          FilledButton.tonalIcon(
            onPressed: onRescan,
            icon: const Icon(KIcons.rescan),
            label: Text(l10n.scanSetupRescan),
          ),
      ],
    );
  }
}

/// A rescan finished and Android still holds no music: what to check.
class FolderSheetStillNoMusic extends StatelessWidget {
  const FolderSheetStillNoMusic({super.key, required this.onRescan});

  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FolderSheetFrame(
      icon: KIcons.folderOff,
      title: Text(l10n.scanSetupStillNoMusicTitle),
      children: [
        FolderSheetBody(l10n.scanSetupStillNoMusicBody),
        StillNoMusicTips(
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        TextButton.icon(
          onPressed: onRescan,
          icon: const Icon(KIcons.rescan),
          label: Text(l10n.scanSetupRescan),
        ),
      ],
    );
  }
}

/// The two things to check when a rescan finds nothing, as bullet lines.
class StillNoMusicTips extends StatelessWidget {
  const StillNoMusicTips({super.key, required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tip in [
          l10n.scanSetupStillNoMusicTipShared,
          l10n.scanSetupStillNoMusicTipRestart,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: KSpace.x1),
            child: Text('• $tip', style: style),
          ),
      ],
    );
  }
}

/// The list could not be read (or the rescan failed): what happened and a
/// retry.
class FolderSheetFailed extends StatelessWidget {
  const FolderSheetFailed({
    super.key,
    required this.title,
    required this.onRetry,
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FolderSheetFrame(
      // The existing warning glyph: kanaru_ui has no error icon yet.
      icon: KIcons.permissionMissing,
      isError: true,
      title: Text(title),
      children: [
        FolderSheetBody(l10n.scanSetupFolderListFailedBody),
        FilledButton.tonal(
          onPressed: onRetry,
          child: Text(l10n.scanSetupRetry),
        ),
      ],
    );
  }
}

/// A strip above the list: the result of a rescan, or its failure.
class FolderSheetBanner extends StatelessWidget {
  const FolderSheetBanner({
    super.key,
    required this.icon,
    required this.child,
    this.action,
    this.isError = false,
  });

  final IconData icon;
  final Widget child;
  final Widget? action;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onColor = isError
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: isError ? scheme.errorContainer : scheme.secondaryContainer,
        shape: KShape.of(KRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x3,
          ),
          child: Row(
            children: [
              Icon(icon, size: KIconSize.sm, color: onColor),
              const KGap(KSpace.x3),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: onColor),
                  child: child,
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

/// The banner after a rescan that found [found] songs.
class FolderSheetRescanDone extends StatelessWidget {
  const FolderSheetRescanDone({super.key, required this.found});

  final int found;

  @override
  Widget build(BuildContext context) => FolderSheetBanner(
    icon: KIcons.check,
    child: Text(AppLocalizations.of(context).scanSetupRescanDone(found)),
  );
}

/// The banner when the rescan itself failed and the list is still shown.
class FolderSheetRescanFailed extends StatelessWidget {
  const FolderSheetRescanFailed({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FolderSheetBanner(
      icon: KIcons.permissionMissing,
      isError: true,
      action: TextButton(onPressed: onRetry, child: Text(l10n.scanSetupRetry)),
      child: Text(l10n.scanSetupRescanFailed),
    );
  }
}

/// "Can't see your folder? Rescan", the last row of the list; off while a
/// rescan runs.
class FolderSheetRescanRow extends StatelessWidget {
  const FolderSheetRescanRow({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SetupAddRow(
    icon: KIcons.rescan,
    label: Text(AppLocalizations.of(context).scanSetupRescanRow),
    onTap: onTap,
  );
}

/// Android is indexing: bold title, an indeterminate bar (a still 40 % bar
/// with animations off), the scope line and, in the sheet, the line that
/// closing the sheet does not stop it. No count.
class RescanProgress extends StatelessWidget {
  const RescanProgress({super.key, this.inSheet = false});

  final bool inSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: inSheet
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.scanSetupRescanning,
            textAlign: inSheet ? TextAlign.center : TextAlign.start,
            style: (inSheet ? textTheme.titleMedium : textTheme.bodyMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const KGap(KSpace.x2),
          ClipRRect(
            borderRadius: KRadius.full,
            child: LinearProgressIndicator(
              value: still ? 0.4 : null,
              minHeight: KSpace.x1,
              backgroundColor: scheme.secondaryContainer,
            ),
          ),
          const KGap(KSpace.x2),
          Text(
            l10n.scanSetupRescanningBody,
            textAlign: inSheet ? TextAlign.center : TextAlign.start,
            style: textTheme.bodyMedium?.merge(muted),
          ),
          if (inSheet) ...[
            const KGap(KSpace.x1),
            Text(
              l10n.scanSetupRescanningSheetNote,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.merge(muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The sheet's scanning state: the hero frame around [RescanProgress].
class FolderSheetScanning extends StatelessWidget {
  const FolderSheetScanning({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(child: Icon(KIcons.rescan, size: KIconSize.hero)),
      KGap(KSpace.x2),
      RescanProgress(inSheet: true),
    ],
  );
}
