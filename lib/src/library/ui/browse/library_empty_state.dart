import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/library_settings_focus.dart';
import '../library_settings_links.dart';

/// Shown instead of every list when the library holds no visible track.
/// "Chọn thư mục nhạc" opens Settings › Library at the music folders.
class LibraryEmptyState extends ConsumerWidget {
  const LibraryEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: _content(context, ref, l10n, scheme, textTheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          KIcons.library,
          size: KIconSize.hero,
          color: scheme.onSurfaceVariant,
        ),
        const KGap(KSpace.x3),
        Text(l10n.libraryEmptyTitle, style: textTheme.titleMedium),
        const KGap(KSpace.x1),
        Text(
          l10n.libraryEmptyMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const KGap(KSpace.x4),
        FilledButton.tonal(
          onPressed: () => openLibrarySettings(
            context,
            ref,
            focus: LibrarySettingsAnchor.folders,
          ),
          child: Text(l10n.libraryChooseFolders),
        ),
      ],
    );
  }
}
