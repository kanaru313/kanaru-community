import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_view/composer_draft.dart';
import 'composer/composer_text_controller.dart';

/// Gives the composer its text controller (one that paints `{{variables}}`)
/// and focus node, backed by the
/// keep-alive draft, so what was typed (and where the cursor was) comes back
/// after the chat left the screen, and a focus request is honoured by exactly
/// one composer even while the chat is still being built.
///
/// The draft is written on every change, not only on dispose: a provider must
/// not be changed while the tree is being torn down. It is also read back, so
/// a part that writes the draft (a prompt chip) changes the field.
class ComposerDraftBinding extends ConsumerStatefulWidget {
  const ComposerDraftBinding({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ComposerTextController controller,
    FocusNode focusNode,
  )
  builder;

  @override
  ConsumerState<ComposerDraftBinding> createState() =>
      _ComposerDraftBindingState();
}

class _ComposerDraftBindingState extends ConsumerState<ComposerDraftBinding> {
  late final ComposerTextController _controller =
      ComposerTextController.fromValue(ref.read(composerDraftProvider));
  final FocusNode _focus = FocusNode(debugLabel: 'chat composer');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_save);
    // Someone else wrote the draft (a prompt chip): show it.
    ref.listenManual(composerDraftProvider, (_, next) {
      // The draft has no composing range: compare without it, or every
      // keystroke of an IME composition would be undone.
      final own = _controller.value.copyWith(composing: TextRange.empty);
      if (next != own) _controller.value = next;
    });
    ref.listenManual(composerFocusRequestProvider, (_, pending) {
      if (pending) _takeRequest();
    }, fireImmediately: true);
  }

  void _save() =>
      ref.read(composerDraftProvider.notifier).set(_controller.value);

  /// Focus after the frame (the field may not be attached yet); the request is
  /// consumed there, so of two composers alive during a swap only the first
  /// one to run finds it pending.
  void _takeRequest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(composerFocusRequestProvider.notifier).consume()) return;
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_save)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _controller, _focus);
}
