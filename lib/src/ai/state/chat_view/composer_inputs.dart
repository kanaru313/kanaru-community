import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../playback/state/player_ready.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/state/queue_view_provider.dart';
import '../../data/ai_settings_store.dart' show aiPromptsSetting;
import '../../domain/conversation/parts.dart';
import '../../domain/settings/prompt_template.dart';
import '../../domain/settings/tool_groups.dart';
import '../../domain/variables/chip_ref.dart';
import '../../domain/variables/variable_catalog.dart';
import '../ai_settings_providers.dart';

/// What the composer reads from the user's settings, in one value so a test
/// (or a screen without a settings store) replaces one provider.
class ComposerSettings {
  ComposerSettings({
    Set<AiToolGroup>? enabledGroups,
    this.varBypass = false,
    List<PromptTemplate>? prompts,
  }) : enabledGroups = enabledGroups ?? AiToolGroup.values.toSet(),
       prompts = prompts ?? defaultPrompts();

  /// The privacy groups whose tools are on.
  final Set<AiToolGroup> enabledGroups;

  /// A variable or chip may fill from a source whose group is off.
  final bool varBypass;

  /// The saved prompts, in the user's order (disabled ones included).
  final List<PromptTemplate> prompts;

  bool groupEnabled(AiToolGroup group) => enabledGroups.contains(group);

  /// An attached chip whose data the send would refuse (its group is off).
  bool isStruck(ChipPart chip) =>
      !varBypass && !groupEnabled(chipGroup(chip.kind));

  /// The prompts the user left on.
  List<PromptTemplate> get enabledPrompts => [
    for (final p in prompts)
      if (p.enabled && !p.isUnknown) p,
  ];

  static List<PromptTemplate> defaultPrompts() =>
      List.of(aiPromptsSetting.defaultValue);
}

final composerSettingsProvider = Provider<ComposerSettings>(
  (ref) => ComposerSettings(
    enabledGroups: {
      for (final g in AiToolGroup.values)
        if (ref.watch(aiToolGroupProvider(g))) g,
    },
    varBypass: ref.watch(aiVarBypassProvider),
    prompts: ref.watch(aiPromptsProvider),
  ),
);

/// Whether the data a prompt's variables read exists right now.
class ChatPromptData {
  const ChatPromptData({this.hasPlaying = true, this.hasQueue = true});

  final bool hasPlaying;
  final bool hasQueue;
}

/// What a prompt chip lacks, for the reason shown under its label.
enum PromptLack { noPlaying, emptyQueue }

/// The first thing [body]'s variables need that [data] does not have.
PromptLack? promptLack(String body, ChatPromptData data) {
  for (final name in _names.allMatches(body).map((m) => m[1]!.trim())) {
    switch (AiVariable.fromName(name)) {
      case AiVariable.nowPlaying ||
          AiVariable.title ||
          AiVariable.artist ||
          AiVariable.album ||
          AiVariable.lyrics:
        if (!data.hasPlaying) return PromptLack.noPlaying;
      case AiVariable.queue:
        if (!data.hasQueue) return PromptLack.emptyQueue;
      case AiVariable.input || null:
        break;
    }
  }
  return null;
}

final _names = RegExp(r'\{\{([^{}]*)\}\}');

/// Playing track and queue, read only once the player exists (reading them
/// earlier would create it while a widget builds).
final chatPromptDataProvider = Provider<ChatPromptData>((ref) {
  if (!ref.watch(playerCreatedProvider)) {
    return const ChatPromptData(hasPlaying: false, hasQueue: false);
  }
  return ChatPromptData(
    hasPlaying: ref.watch(hasCurrentTrackProvider),
    hasQueue: ref.watch(
      queueViewProvider.select((q) => q.value?.items.isNotEmpty ?? false),
    ),
  );
});

/// A request to open the model picker (the "Đổi model" button of an error
/// card). It stays pending until a composer takes it, so a request made while
/// the chat is being built is kept, and only one composer takes it.
class ModelPickerRequest extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  /// Takes the request; true for the one caller that finds it pending.
  bool consume() {
    if (!state) return false;
    state = false;
    return true;
  }
}

final modelPickerRequestProvider = NotifierProvider<ModelPickerRequest, bool>(
  ModelPickerRequest.new,
);
