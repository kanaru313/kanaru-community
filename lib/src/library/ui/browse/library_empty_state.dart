import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Shown instead of every list when the library holds no visible track.
/// "Chọn thư mục nhạc" is dimmed until Settings › Library › Folders exists.
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Scrolls when a short window or large text leaves too little room, and
    // stays centred when there is room.
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(KSpace.x6),
              child: _content(context, l10n, scheme, textTheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(KIcons.library, size: KSpace.x9, color: scheme.onSurfaceVariant),
        const KGap(KSpace.x3),
        Text(l10n.libraryEmptyTitle, style: textTheme.titleMedium),
        const KGap(KSpace.x1),
        Text(
          l10n.libraryEmptyMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const KGap(KSpace.x4),
        Tooltip(
          message: l10n.appComingSoon,
          child: FilledButton.tonal(
            onPressed: null,
            child: Text(l10n.libraryChooseFolders),
          ),
        ),
      ],
    );
  }
}
