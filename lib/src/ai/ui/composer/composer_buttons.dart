import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/chat_view/composer_inputs.dart';
import '../../state/chat_view/composer_view.dart';
import 'chat_plugin_icon.dart';
import 'model_picker.dart';
import 'permission_picker.dart';
import 'plugin_picker.dart';
import 'send_button.dart';

/// The button row under the field: plugin icon, permission icon with a
/// chevron, the model, then Send / Stop. The pickers open from here (a
/// dropdown above the button on desktop, a sheet on the phone).
class ComposerButtons extends ConsumerStatefulWidget {
  const ComposerButtons({
    super.key,
    required this.view,
    required this.onSend,
    required this.onStop,
  });

  final ComposerView view;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  ConsumerState<ComposerButtons> createState() => _ComposerButtonsState();
}

class _ComposerButtonsState extends ConsumerState<ComposerButtons> {
  final _pluginKey = GlobalKey();
  final _permissionKey = GlobalKey();
  final _modelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ref.listenManual(modelPickerRequestProvider, (_, pending) {
      if (pending) _takeModelRequest();
    }, fireImmediately: true);
  }

  /// Opens the model picker for a request ("Đổi model" on an error card),
  /// after the frame so the button is laid out. A locked chat drops it.
  void _takeModelRequest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(modelPickerRequestProvider.notifier).consume()) return;
      if (!widget.view.modelPickerEnabled) return;
      showModelPicker(context, ref, anchor: _modelKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final view = widget.view;
    final plugin = view.plugin;
    // Only an uninstalled plugin reads as gone; while plugins load, or when
    // none is installed yet, the button shows the AI glyph.
    final removed = plugin == null && view.notice is NoticeRemoved;
    final permission = permissionName(l10n, view.permission);
    final modelText = view.modelNeeded || view.model == null
        ? l10n.aiChatModelNeeded
        : view.model!;
    return Row(
      children: [
        KeyedSubtree(
          key: _pluginKey,
          child: KIconButton(
            tooltip: plugin != null
                ? l10n.aiChatPluginTooltip(plugin.name)
                : removed
                ? l10n.aiChatPluginGone
                : l10n.aiChatActionPickPlugin,
            onPressed: view.pluginPickerEnabled
                ? () => showPluginPicker(context, ref, anchor: _pluginKey)
                : null,
            child: ChatPluginIcon(
              installId: plugin?.installId,
              removed: removed,
            ),
          ),
        ),
        KeyedSubtree(
          key: _permissionKey,
          child: KIconButton(
            tooltip: l10n.aiChatPermissionTooltip(
              permission,
              permissionDescription(l10n, view.permission),
            ),
            semanticLabel: l10n.aiChatPermissionLabel(permission),
            onPressed: view.permissionPickerEnabled
                ? () =>
                      showPermissionPicker(context, ref, anchor: _permissionKey)
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(permissionIcon(view.permission), size: KIconSize.sm),
                const Icon(KIcons.collapse, size: KIconSize.xs),
              ],
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: KeyedSubtree(
              key: _modelKey,
              child: Semantics(
                button: true,
                label: l10n.aiChatModelLabel(modelText),
                excludeSemantics: true,
                enabled: view.modelPickerEnabled,
                child: TextButton(
                  onPressed: view.modelPickerEnabled
                      ? () => showModelPicker(context, ref, anchor: _modelKey)
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: view.modelNeeded
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(modelText, overflow: TextOverflow.ellipsis),
                      ),
                      const Icon(KIcons.collapse, size: KIconSize.xs),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SendButton(
          action: view.action,
          canSend: view.canSend,
          toolsRunning: view.toolsRunning,
          onSend: widget.onSend,
          onStop: widget.onStop,
        ),
      ],
    );
  }
}
