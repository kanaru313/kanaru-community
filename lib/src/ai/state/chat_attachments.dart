import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/domain/ask_ai_target.dart';
import '../domain/conversation/parts.dart';
import '../domain/variables/chip_ref.dart';

/// Chips attached to the message being written, and the chips offered as
/// one-tap suggestions (the page on screen and the current selection).
class ChatAttachments {
  const ChatAttachments({
    this.attached = const [],
    this.suggestions = const [],
  });

  final List<ChipPart> attached;
  final List<ChipPart> suggestions;

  ChatAttachments copyWith({
    List<ChipPart>? attached,
    List<ChipPart>? suggestions,
  }) => ChatAttachments(
    attached: attached ?? this.attached,
    suggestions: suggestions ?? this.suggestions,
  );
}

/// Same thing a chip points at (kind, key and track ids), whatever its label.
bool sameChip(ChipPart a, ChipPart b) =>
    a.kind == b.kind &&
    a.ref == b.ref &&
    a.tracks.length == b.tracks.length &&
    [for (final t in a.tracks) t.trackId].join(',') ==
        [for (final t in b.tracks) t.trackId].join(',');

/// The chips of the composer. An attached chip stays until the user removes
/// it or a send is accepted (`clearAttached`); a refused send keeps them.
class ChatAttachmentsNotifier extends Notifier<ChatAttachments> {
  @override
  ChatAttachments build() => const ChatAttachments();

  /// Attaches [chip]; one that points at the same thing is not added twice.
  void attach(ChipPart chip) {
    if (state.attached.any((c) => sameChip(c, chip))) return;
    state = state.copyWith(attached: [...state.attached, chip]);
  }

  /// Attaches what an "Ask AI" entry handed over.
  void attachTarget(AskAiTarget target) {
    final ref = chipRefOf(target);
    attach(
      ChipPart(
        kind: ref.kind,
        ref: ref.ref,
        label: ref.label,
        tracks: ref.tracks,
      ),
    );
  }

  void detach(ChipPart chip) {
    state = state.copyWith(
      attached: [
        for (final c in state.attached)
          if (!sameChip(c, chip)) c,
      ],
    );
  }

  /// Replaces the suggestions (the chat screen calls it when the page or the
  /// selection changes).
  void setSuggestions(List<ChipPart> suggestions) {
    state = state.copyWith(suggestions: List.unmodifiable(suggestions));
  }

  /// Called by the session once a send was accepted: drops the chips that
  /// were [sent] with the message (all of them when null). A chip attached
  /// while the send was being prepared stays.
  void clearAttached([List<ChipPart>? sent]) {
    final keep = sent == null
        ? const <ChipPart>[]
        : [
            for (final c in state.attached)
              if (!sent.any((s) => sameChip(s, c))) c,
          ];
    if (keep.length == state.attached.length) return;
    state = state.copyWith(attached: keep);
  }
}

final chatAttachmentsProvider =
    NotifierProvider<ChatAttachmentsNotifier, ChatAttachments>(
      ChatAttachmentsNotifier.new,
    );
