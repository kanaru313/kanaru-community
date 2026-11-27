import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../lyrics/state/playing_lyrics_providers.dart';
import '../../../lyrics/ui/lyrics_for_track_modal.dart';
import '../../domain/settings/tool_groups.dart';
import '../../domain/variables/variable_catalog.dart';
import '../../domain/variables/variable_values.dart' show queueShortEntries;
import '../../domain/variables/variable_filler.dart';
import '../../state/chat_attachments.dart';
import '../../state/chat_send.dart';
import '../../state/chat_view/composer_inputs.dart';
import '../../state/chat_view/composer_view.dart';
import '../chat_host.dart';
import '../chat_links.dart';
import 'chip_labels.dart';

/// Opens the lyrics search for the playing song ("Tìm lời bài này"). A
/// provider so a test can stand in for the modal.
final chatFindLyricsProvider = Provider<void Function(BuildContext context)>(
  (ref) => (context) {
    final id = ref.read(playingLyricsProvider).trackId;
    if (id != null) showLyricsForTrack(context, id);
  },
);

/// Names of the variables a refused send could not fill, so the field can
/// paint them as warnings.
Set<String> missingVariableNames(ComposerNotice? notice) => {
  if (notice is NoticeMissingData)
    for (final i in notice.issues)
      if (i is VariableIssue)
        switch (i.issue) {
          FillMissing(:final variable) => variable.name,
          FillGroupOff(:final variable) => variable.name,
          FillLeftoverInput() => AiVariable.input.name,
        },
};

/// The one note above the composer: why nothing can be sent, what a refused
/// send left, or a gentle remark about the model. The caller removes it when
/// the state it describes changes.
class ComposerNoticeView extends ConsumerWidget {
  const ComposerNoticeView({
    super.key,
    required this.notice,
    required this.model,
    required this.onPickPlugin,
    required this.onPickModel,
    required this.onSendShort,
  });

  final ComposerNotice notice;
  final String? model;
  final VoidCallback onPickPlugin;
  final VoidCallback onPickModel;
  final VoidCallback onSendShort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final host = ref.read(chatHostProvider);
    final sendNotice = ref.read(composerSendNoticeProvider.notifier);
    void openPlugin(String id) => host.openSettings(aiPluginPageLocation(id));
    void dismiss() => sendNotice.clear();

    KInlineNotice warn(
      String message, {
      String? action,
      VoidCallback? onAction,
      String? second,
      VoidCallback? onSecond,
      bool dismissible = false,
      IconData icon = KIcons.warning,
    }) => _warn(
      l10n,
      dismiss,
      message,
      action: action,
      onAction: onAction,
      second: second,
      onSecond: onSecond,
      dismissible: dismissible,
      icon: icon,
    );

    return switch (notice) {
      NoticeNeedsKey(:final plugin, :final installId) => warn(
        l10n.aiChatNoticeNeedsKey(plugin),
        action: l10n.aiChatActionOpenPluginSettings,
        onAction: () => openPlugin(installId),
      ),
      NoticeNeedsModel(:final plugin) => warn(
        l10n.aiChatNoticeNeedsModel(plugin),
        action: l10n.aiChatActionPickModel,
        onAction: onPickModel,
      ),
      NoticeNeedsConfig(:final plugin, :final installId, :final titles) => warn(
        l10n.aiChatNoticeNeedsConfig(plugin, titles.join(', ')),
        action: l10n.aiChatActionOpenPluginSettings,
        onAction: () => openPlugin(installId),
      ),
      NoticeRemoved(:final plugin) => warn(
        plugin == null
            ? l10n.aiChatNoticeRemoved
            : l10n.aiChatNoticeRemovedNamed(plugin),
        action: l10n.aiChatActionPickPlugin,
        onAction: onPickPlugin,
        icon: KIcons.extension,
      ),
      NoticeReinstalled(:final plugin) => warn(
        plugin == null
            ? l10n.aiChatNoticeRemoved
            : l10n.aiChatNoticeReinstalled(plugin),
        action: l10n.aiChatActionPickPlugin,
        onAction: onPickPlugin,
        icon: KIcons.extension,
      ),
      NoticeStruckChip(:final chip) => warn(
        l10n.aiChatNoticeStruckChip(chipGroupName(l10n, chip.kind)),
        action: l10n.aiChatActionDropChip,
        onAction: () => ref.read(chatAttachmentsProvider.notifier).detach(chip),
        second: l10n.aiChatActionAiSettings,
        onSecond: () => host.openSettings(aiSettingsLocation),
        icon: KIcons.advanced,
      ),
      NoticeMissingData(:final issues) => _missing(
        context,
        ref,
        l10n,
        issues.first,
        dismiss,
      ),
      NoticeOversize(:final variables) => _oversize(
        l10n,
        ref,
        variables,
        onSendShort,
        dismiss,
      ),
      NoticeSendFailed() => warn(
        l10n.aiChatNoticeSendFailed,
        dismissible: true,
      ),
      NoticeNoTools(:final model) => KInlineNotice(
        icon: KIcons.info,
        tone: KInlineNoticeTone.quiet,
        message: l10n.aiChatNoticeNoTools(model),
      ),
    };
  }

  /// "{{queue}} có 412 bài, quá giới hạn…" with the short version as the
  /// main action and Cancel next to it.
  Widget _oversize(
    AppLocalizations l10n,
    WidgetRef ref,
    List<AiVariable> variables,
    VoidCallback onSendShort,
    VoidCallback dismiss,
  ) {
    final queue = variables.contains(AiVariable.queue);
    final count = queue ? ref.watch(chatQueueLengthProvider) : null;
    final tags = variables.map((v) => '{{${v.name}}}').join(', ');
    final modelName = model ?? '';
    return _warn(
      l10n,
      dismiss,
      variables.length == 1 && count != null
          ? l10n.aiChatNoticeOversizeQueue(tags, count, modelName)
          : l10n.aiChatNoticeOversize(tags, modelName),
      action: queue
          ? l10n.aiChatActionSendShortQueue(queueShortEntries)
          : l10n.aiChatActionSendShort,
      onAction: onSendShort,
      second: l10n.aiChatActionCancel,
      onSecond: dismiss,
    );
  }

  Widget _missing(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SendIssue issue,
    VoidCallback dismiss,
  ) {
    KInlineNotice warn(
      String message, {
      String? action,
      VoidCallback? onAction,
      String? second,
      VoidCallback? onSecond,
      IconData icon = KIcons.warning,
    }) => _warn(
      l10n,
      dismiss,
      message,
      action: action,
      onAction: onAction,
      second: second,
      onSecond: onSecond,
      dismissible: true,
      icon: icon,
    );

    String tag(AiVariable v) => '{{${v.name}}}';
    final host = ref.read(chatHostProvider);
    switch (issue) {
      case VariableIssue(issue: FillMissing(:final variable)):
        final lyrics = variable == AiVariable.lyrics;
        return warn(
          switch (variable) {
            AiVariable.lyrics => l10n.aiChatNoticeMissingLyrics(tag(variable)),
            AiVariable.queue => l10n.aiChatNoticeMissingQueue(tag(variable)),
            _ => l10n.aiChatNoticeMissingPlaying(tag(variable)),
          },
          action: lyrics ? l10n.aiChatActionFindLyrics : null,
          onAction: lyrics
              ? () => ref.read(chatFindLyricsProvider)(context)
              : null,
        );
      case VariableIssue(issue: FillGroupOff(:final variable)):
        return warn(
          l10n.aiChatNoticeGroupOff(
            toolGroupName(l10n, variable.group ?? AiToolGroup.nowPlaying),
            tag(variable),
          ),
          action: l10n.aiChatActionAiSettings,
          onAction: () => host.openSettings(aiSettingsLocation),
          icon: KIcons.advanced,
        );
      case VariableIssue(issue: FillLeftoverInput()):
        return warn(l10n.aiChatNoticeLeftoverInput(tag(AiVariable.input)));
      case ChipUnavailable(:final chip):
        return warn(
          l10n.aiChatNoticeChipUnavailable(chipLabel(l10n, chip)),
          action: l10n.aiChatActionDropChip,
          onAction: () =>
              ref.read(chatAttachmentsProvider.notifier).detach(chip),
          icon: KIcons.advanced,
        );
      case ChipGroupOff(:final chip):
        return warn(
          l10n.aiChatNoticeStruckChip(chipGroupName(l10n, chip.kind)),
          action: l10n.aiChatActionDropChip,
          onAction: () =>
              ref.read(chatAttachmentsProvider.notifier).detach(chip),
          icon: KIcons.advanced,
        );
    }
  }
}

KInlineNotice _warn(
  AppLocalizations l10n,
  VoidCallback dismiss,
  String message, {
  String? action,
  VoidCallback? onAction,
  String? second,
  VoidCallback? onSecond,
  bool dismissible = false,
  IconData icon = KIcons.warning,
}) => KInlineNotice(
  icon: icon,
  tone: KInlineNoticeTone.warning,
  message: message,
  actionLabel: action,
  onAction: onAction,
  secondaryActionLabel: second,
  onSecondaryAction: onSecond,
  onDismiss: dismissible ? dismiss : null,
  dismissLabel: dismissible ? l10n.aiChatNoticeDismiss : null,
);
