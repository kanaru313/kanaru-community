import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../plugins/state/store_ops.dart' show pluginIconProvider;
import '../../../state/translation/translation_services_provider.dart';
import '../../../state/translation/translation_tune_provider.dart';

/// The picture of a translate plugin: its icon, else its first letter.
class TranslateServiceIcon extends ConsumerWidget {
  const TranslateServiceIcon({
    super.key,
    required this.service,
    this.size = KIconSize.md,
  });

  final TranslateService service;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KSourceAvatar(
    label: service.name,
    size: size,
    imageBytes: ref.watch(pluginIconProvider(service.installId)).value,
  );
}

/// The small "AI" tag after an AI plugin's name. On a chosen row ([onTint])
/// the row tint is the same container colour, so the tag takes a 12 % pill of
/// its own text colour (as the mockup) to stay visible.
class TranslateAiTag extends StatelessWidget {
  const TranslateAiTag({super.key, this.onTint = false});

  final bool onTint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onTint
            ? scheme.onSecondaryContainer.withValues(alpha: 0.12)
            : scheme.secondaryContainer,
        borderRadius: KRadius.full,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x2,
          vertical: KSpace.x1 / 2,
        ),
        child: Text(
          AppLocalizations.of(context).lyricsTranslateAiTag,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Service name with its AI tag; a long name is cut, the tag stays.
class TranslateServiceName extends StatelessWidget {
  const TranslateServiceName(this.service, {super.key, this.selected = false});

  final TranslateService service;

  /// The row is the chosen one (its tint is behind the tag).
  final bool selected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      if (service.ai) ...[
        const KGap(KSpace.x2),
        TranslateAiTag(onTint: selected),
      ],
    ],
  );
}

/// The service row: icon, name with the AI tag, the scope (every song) and
/// ›. Red "Chưa chọn dịch vụ" / "Dịch vụ mặc định đã bị gỡ…" without one.
class TranslateServiceRow extends StatelessWidget {
  const TranslateServiceRow({
    super.key,
    required this.services,
    required this.onTap,
  });

  final TranslateServices services;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final service = services.current;
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: KListRow(
        leading: service == null
            ? Icon(KIcons.offline, color: scheme.error)
            : TranslateServiceIcon(service: service),
        title: service == null
            ? Text(l10n.lyricsTranslateServiceTitle)
            : TranslateServiceName(service),
        subtitle: service == null
            ? Text(
                services.gone
                    ? l10n.lyricsTranslateServiceGone
                    : l10n.lyricsTranslateServiceUnset,
                style: TextStyle(color: scheme.error),
              )
            : Text(l10n.lyricsTranslateServiceScope),
        trailing: const Icon(KIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}

/// "Tinh chỉnh AI": model · style of the chosen AI plugin.
class TranslateTuneRow extends ConsumerWidget {
  const TranslateTuneRow({
    super.key,
    required this.service,
    required this.onTap,
  });

  final TranslateService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tune = ref.watch(translateTuneProvider(service.installId)).value;
    final summary = [tune?.modelTitle, tune?.styleTitle].nonNulls.join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: KListRow(
        leading: const Icon(KIcons.sortAdvanced),
        title: Text(l10n.lyricsTranslateTuneTitle),
        subtitle: summary.isEmpty ? null : Text(summary),
        trailing: const Icon(KIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}
