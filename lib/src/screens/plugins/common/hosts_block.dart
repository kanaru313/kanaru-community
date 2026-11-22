import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Which sentence of consent closes the block.
enum HostsConsent { none, install, update }

/// "Gửi dữ liệu tới": the fixed hosts (mono), a sentence for every wildcard,
/// one line per field the user types an address into, and the consent line.
/// [newHosts] (an update) sit on `errorContainer` with a NEW badge. Always
/// visible text: installing or updating is the consent.
class HostsBlock extends StatelessWidget {
  const HostsBlock({
    super.key,
    required this.hosts,
    this.newHosts = const [],
    this.endpointFields = const [],
    this.consent = HostsConsent.none,
  });

  final List<String> hosts;
  final List<String> newHosts;

  /// Labels of the `format: url` fields of the plugin.
  final List<String> endpointFields;
  final HostsConsent consent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final all = [...hosts, ...newHosts];
    final wildcards = [
      for (final host in all)
        if (host.startsWith('*.'))
          l10n.pluginsPkgWildcardHost(host.substring(2)),
    ];
    final empty = all.isEmpty && endpointFields.isEmpty;
    final soft = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: KSpace.x2,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.pluginsPkgSendTo, style: text.titleSmall),
        ),
        if (all.isNotEmpty)
          Wrap(
            spacing: KSpace.x2,
            runSpacing: KSpace.x2,
            children: [
              for (final host in hosts) _HostChip(host: host),
              for (final host in newHosts) _HostChip(host: host, isNew: true),
            ],
          ),
        if (wildcards.isNotEmpty)
          Text(l10n.pluginsPkgWildcard(wildcards.join(' · ')), style: soft),
        for (final field in endpointFields)
          Row(
            spacing: KSpace.x2,
            children: [
              Icon(KIcons.edit, size: KIconSize.sm, color: scheme.primary),
              Expanded(
                child: Text(
                  l10n.pluginsPkgUserEndpoint(field),
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
        if (empty) Text(l10n.pluginsPkgNoHosts, style: soft),
        if (!empty && consent != HostsConsent.none)
          Text(
            consent == HostsConsent.update
                ? l10n.pluginsPkgConsentUpdate
                : l10n.pluginsPkgConsentInstall,
            style: text.bodyMedium,
          ),
      ],
    );
  }
}

class _HostChip extends StatelessWidget {
  const _HostChip({required this.host, this.isNew = false});

  final String host;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.bodySmall;
    final color = isNew ? scheme.onErrorContainer : scheme.onSurface;
    final label = host.startsWith('*.')
        ? AppLocalizations.of(context).pluginsPkgWildcardHost(host.substring(2))
        : host;
    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isNew ? scheme.errorContainer : scheme.surfaceContainerHigh,
          borderRadius: KRadius.xs,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x2,
            vertical: KSpace.x1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: KSpace.x2,
            children: [
              Flexible(
                child: Text(
                  host,
                  style: text?.copyWith(color: color, fontFamily: 'monospace'),
                ),
              ),
              if (isNew)
                Text(
                  AppLocalizations.of(context).pluginsPkgNewBadge,
                  style: text?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
