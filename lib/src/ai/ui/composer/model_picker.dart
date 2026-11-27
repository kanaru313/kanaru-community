import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/chat_providers.dart';
import '../../state/chat_session.dart';
import '../../state/chat_view/composer_view.dart';

/// "200K", "1M", "32K": a context size in tokens, short.
String contextSizeText(int tokens) {
  String trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  if (tokens >= 1000000) return '${trim(tokens / 1000000)}M';
  if (tokens >= 1000) return '${trim(tokens / 1000)}K';
  return '$tokens';
}

/// What a model can do as one line: image, tools, context, and "Tuỳ chỉnh" for
/// a model the user added. A capability the model lacks is struck through.
Widget modelTags(AppLocalizations l10n, ChatModelOption model) {
  final caps = model.capabilities;
  TextSpan tag(String label, bool on) => TextSpan(
    text: label,
    style: on ? null : const TextStyle(decoration: TextDecoration.lineThrough),
  );
  const sep = TextSpan(text: ' · ');
  return Text.rich(
    TextSpan(
      children: [
        tag(l10n.aiChatCapVision, caps.vision),
        sep,
        tag(l10n.aiChatCapTools, caps.tools),
        sep,
        TextSpan(text: contextSizeText(caps.context)),
        if (model.isCustom) TextSpan(text: ' · ${l10n.aiChatModelCustom}'),
      ],
    ),
  );
}

/// The same line as plain words, for screen readers.
String modelTagsSpoken(AppLocalizations l10n, ChatModelOption model) {
  final caps = model.capabilities;
  return [
    if (caps.vision) l10n.aiChatCapVision,
    if (caps.tools) l10n.aiChatCapTools,
    contextSizeText(caps.context),
    if (model.isCustom) l10n.aiChatModelCustom,
  ].join(', ');
}

/// Picks the model of the open chat among its plugin's models and the ones
/// the user added (text rows, with capability tags).
Future<void> showModelPicker(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey? anchor,
}) async {
  final l10n = AppLocalizations.of(context);
  final view = ref.read(composerViewProvider);
  final plugin = view.plugin;
  if (plugin == null) return;
  final session = ref.read(chatSessionProvider.notifier);
  final chosen = await showSelectionPicker<String>(
    context,
    anchor: anchor,
    selected: view.model,
    title: Text(l10n.aiChatModelPickerTitle(plugin.name)),
    header: Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x2,
        KSpace.x4,
        KSpace.x2,
      ),
      child: Text(l10n.aiChatModelPickerCaption),
    ),
    options: [
      for (final m in plugin.models)
        SelectionOption<String>(
          value: m.id,
          title: Text(m.title),
          subtitle: modelTags(l10n, m),
          hint: modelTagsSpoken(l10n, m),
        ),
    ],
  );
  if (chosen != null && chosen != view.model) await session.switchModel(chosen);
}
