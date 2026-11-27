import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/output/chat_readiness.dart';
import '../../../../ai/state/ai_settings_providers.dart';
import '../../../../ai/state/chat_providers.dart';
import '../../../../ai/ui/ai_settings_link.dart';
import '../../../../plugins/state/plugin_store_providers.dart';
import '../../../../plugins/state/store_ops.dart';

/// The name a removed plugin was installed under (its tombstone row keeps
/// it); null when the row is gone or still installed.
final aiRemovedPluginNameProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, installId) async {
      final row = await ref.watch(pluginRowsProvider).byId(installId);
      return row != null && row.removedAt != null ? row.name : null;
    });

/// "Dịch vụ AI": the installed AI chat plugins, each with its default model
/// or what it still needs; a tap opens the plugin's own page. While the list
/// loads, or when it cannot be read, there are no rows and no empty note (the
/// provider logs the failure); "Thêm dịch vụ AI" is always there.
class AiServicesSection extends ConsumerWidget {
  const AiServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plugins = ref.watch(chatPluginsProvider);
    final services = plugins.value ?? const <ChatPluginInfo>[];
    final lastUsed = ref.watch(aiLastPluginProvider);
    final title = l10n.aiSetServicesTitle;
    return SetupSection(
      title: Text(title),
      subtitle: _removedLine(l10n, ref, services, lastUsed),
      hint: l10n.aiSetServicesHint,
      hintTooltip: l10n.settingsSectionHintTooltip(title),
      hintTitle: title,
      children: [
        for (final service in services)
          _ServiceRow(
            service: service,
            lastUsed: service.installId == lastUsed,
          ),
        if (plugins.hasValue && services.isEmpty)
          SetupNote(child: Text(l10n.aiSetServicesEmpty)),
        SetupAddRow(
          icon: KIcons.add,
          label: Text(l10n.aiSetServiceAdd),
          onTap: () => context.push(aiPluginStoreLocation),
        ),
      ],
    );
  }

  /// The line under the title when the plugin used last was removed and
  /// others are installed: which one new chats use now.
  Widget? _removedLine(
    AppLocalizations l10n,
    WidgetRef ref,
    List<ChatPluginInfo> services,
    String? lastUsed,
  ) {
    if (lastUsed == null || services.isEmpty) return null;
    // The engine's answer: the plugin new chats really use.
    final nextId = ref.watch(aiChatPluginProvider).value;
    if (nextId == null || nextId == lastUsed) return null;
    final removed = ref.watch(aiRemovedPluginNameProvider(lastUsed)).value;
    final next = services.where((s) => s.installId == nextId).firstOrNull;
    if (removed == null || next == null) return null;
    return Text(l10n.aiSetServicesGone(removed, next.name));
  }
}

class _ServiceRow extends ConsumerWidget {
  const _ServiceRow({required this.service, required this.lastUsed});

  final ChatPluginInfo service;
  final bool lastUsed;

  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final icon = ref.watch(pluginIconProvider(service.installId)).value;
    final (:text, :problem) = _line(l10n);
    return SetupRowFrame(
      leading: KSourceAvatar(
        label: service.name,
        size: _iconSize,
        imageBytes: icon,
      ),
      title: Text(service.name),
      subtitle: Text(
        text,
        style: problem ? TextStyle(color: scheme.error) : null,
      ),
      trailing: Icon(KIcons.chevronRight, color: scheme.onSurfaceVariant),
      onTap: () => context.push(aiPluginPageLocation(service.installId)),
    );
  }

  /// What the plugin's readiness says. A removed or reinstalled plugin cannot
  /// reach this list (it lists live plugins with their current install), so
  /// they read like a ready one.
  ({String text, bool problem}) _line(AppLocalizations l10n) {
    final model = service.defaultModel;
    return switch (service.readiness) {
      ChatNeedsKey() => (text: l10n.aiSetServiceNeedsKey, problem: true),
      // No model chosen reads as the model field still to set up.
      ChatNeedsModel() => (
        text: l10n.aiSetServiceNeedsConfig(l10n.lyricsTranslateModelTitle),
        problem: true,
      ),
      ChatNeedsConfig(:final titles) => (
        text: l10n.aiSetServiceNeedsConfig(titles.join(', ')),
        problem: true,
      ),
      ChatReady() || ChatPluginRemoved() || ChatPluginReinstalled() => (
        text: switch ((model, lastUsed)) {
          (final m?, true) => l10n.aiSetServiceModelLastUsed(m),
          (final m?, false) => m,
          (null, true) => l10n.aiSetServiceLastUsed,
          (null, false) => '',
        },
        problem: false,
      ),
    };
  }
}
