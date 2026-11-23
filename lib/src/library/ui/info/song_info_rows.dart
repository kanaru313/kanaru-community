import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../state/favorites_providers.dart';
import 'song_info_path_row.dart';
import 'song_info_row_actions.dart';
import 'song_info_spec.dart';

/// One [InfoRowSpec] drawn as a `KInfoRow`.
class SongInfoRow extends ConsumerWidget {
  const SongInfoRow({
    super.key,
    required this.spec,
    required this.trackId,
    required this.actions,
  });

  final InfoRowSpec spec;
  final TrackId trackId;
  final SongInfoRowActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unknown = l10n.libraryInfoUnknown;
    if (spec.soon) {
      return KInfoRow(label: spec.label, soon: l10n.appComingSoon);
    }
    switch (spec.kind) {
      case InfoRowKind.favorite:
        return _favorite(context, ref, l10n);
      case InfoRowKind.path:
        return SongInfoPathRow(spec: spec, actions: actions);
      case InfoRowKind.links:
        if (spec.links.isEmpty) {
          return KInfoRow(label: spec.label, unknownText: unknown);
        }
        return KInfoRow(label: spec.label, valueWidget: _links(context));
      case InfoRowKind.text:
        if (spec.muted) {
          return KInfoRow(
            label: spec.label,
            valueWidget: Text(
              spec.value!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return KInfoRow(
          label: spec.label,
          value: spec.value,
          unknownText: spec.value == null ? unknown : null,
          copyText: spec.copyText,
          onCopied: actions.copied,
        );
    }
  }

  Widget _links(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: FontWeight.w500);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 0,
      children: [
        for (var i = 0; i < spec.links.length; i++) ...[
          // The separator is not a link and not read out.
          if (i > 0) ExcludeSemantics(child: Text(', ', style: style)),
          KTextLink(
            text: spec.links[i].text,
            semanticLabel: spec.links[i].semanticLabel,
            overflow: KTextLinkOverflow.wrap,
            onTap: () => actions.openLink(spec.links[i]),
          ),
        ],
        if (spec.badge != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: KSpace.x2),
            child: KChip.tag(label: Text(spec.badge!)),
          ),
      ],
    );
  }

  Widget _favorite(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final on = ref.watch(isFavoriteProvider(trackId));
    return KInfoRow(
      label: spec.label,
      valueWidget: Align(
        alignment: AlignmentDirectional.centerStart,
        child: KChip(
          dense: true,
          selected: on,
          // The pill stays plain; only the heart turns `primary` when liked.
          tintWhenSelected: false,
          icon: Icon(
            on ? KIcons.heartFilled : KIcons.heart,
            color: on ? Theme.of(context).colorScheme.primary : null,
          ),
          label: Text(
            on ? l10n.libraryInfoFavoriteOn : l10n.libraryInfoFavoriteOff,
          ),
          onTap: () => actions.toggleFavorite(!on),
        ),
      ),
    );
  }
}
