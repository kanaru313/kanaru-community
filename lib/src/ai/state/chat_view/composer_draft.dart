import 'package:flutter/widgets.dart' show TextEditingValue;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the user has typed in the composer, selection included. Lives here,
/// not in the composer's controller, so it survives the chat leaving the
/// screen (the right panel swapping to the queue, the panel and the phone
/// page handing over to each other).
class ComposerDraft extends Notifier<TextEditingValue> {
  @override
  TextEditingValue build() => TextEditingValue.empty;

  void set(TextEditingValue value) {
    if (value != state) state = value;
  }
}

final composerDraftProvider = NotifierProvider<ComposerDraft, TextEditingValue>(
  ComposerDraft.new,
);

/// A request to put the cursor in the composer ("Ask AI", a new conversation).
/// It stays pending until a composer takes it, so a request made while the
/// chat is still being built (a panel swap, a page push) is not lost, and
/// two composers alive for a moment cannot both take it.
class ComposerFocusRequest extends Notifier<bool> {
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

final composerFocusRequestProvider =
    NotifierProvider<ComposerFocusRequest, bool>(ComposerFocusRequest.new);
