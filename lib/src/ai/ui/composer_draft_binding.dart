import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_view/composer_draft.dart';

/// Gives the composer its text controller and focus node, backed by the
/// keep-alive draft, so what was typed (and where the cursor was) comes back
/// after the chat left the screen, and a focus request is honoured by exactly
/// one composer even while the chat is still being built.
///
/// The draft is written on every change, not only on dispose: a provider must
/// not be changed while the tree is being torn down.
class ComposerDraftBinding extends ConsumerStatefulWidget {
  const ComposerDraftBinding({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
  )
  builder;

  @override
  ConsumerState<ComposerDraftBinding> createState() =>
      _ComposerDraftBindingState();
}

class _ComposerDraftBindingState extends ConsumerState<ComposerDraftBinding> {
  late final TextEditingController _controller =
      TextEditingController.fromValue(ref.read(composerDraftProvider));
  final FocusNode _focus = FocusNode(debugLabel: 'chat composer');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_save);
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
