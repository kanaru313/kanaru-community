import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'chat_host.dart';
import 'chat_links.dart';

/// The body of a conversation with no message yet: the greeting. [chips] is
/// the place of the prompt chips under it, filled by the composer part.
class ChatEmptyGreeting extends StatelessWidget {
  const ChatEmptyGreeting({super.key, this.chips});

  final Widget? chips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return _EmptyFrame(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: KSpace.x2,
        children: [
          Icon(KIcons.ai, size: KIconSize.xl, color: scheme.primary),
          Text(
            l10n.aiChatEmptyTitle,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              l10n.aiChatEmptyBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      below: chips,
    );
  }
}

/// The body while no `ai-chat` plugin is installed: how to get one. There is
/// no composer in this state.
class ChatNoPluginGuide extends ConsumerWidget {
  const ChatNoPluginGuide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return _EmptyFrame(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: KSpace.x2,
        children: [
          Icon(KIcons.ai, size: KIconSize.xl, color: scheme.primary),
          Text(
            l10n.aiChatGuideTitle,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              l10n.aiChatGuideBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      below: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: KSpace.x2,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: KRadius.lg,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KSpace.x3,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    // The store's puzzle icon: no cloud icon in KIcons yet.
                    child: Icon(KIcons.extension, color: scheme.primary),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiChatGuideCloudTitle,
                          style: text.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.aiChatGuideCloudBody,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: KSpace.x2),
                        FilledButton.tonalIcon(
                          onPressed: () => ref
                              .read(chatHostProvider)
                              .openSettings(aiPluginStoreLocation),
                          icon: const Icon(
                            KIcons.extension,
                            size: KIconSize.sm,
                          ),
                          label: Text(l10n.aiChatGuideCloudAction),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KSpace.x2,
              vertical: KSpace.x1,
            ),
            child: Text(
              l10n.aiChatGuideFoot,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// [header] centred in the free space, [below] at the bottom; scrolls when
/// the window is too short (200 % text, keyboard up).
class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame({required this.header, this.below});

  final Widget header;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x6,
              KSpace.x4,
              KSpace.x2,
            ),
            child: Column(
              children: [
                // Spacers, not an Expanded box: in a panel shorter than the
                // header the column grows and the sliver scrolls.
                const Spacer(),
                header,
                const Spacer(),
                const SizedBox(height: KSpace.x4),
                ?below,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
