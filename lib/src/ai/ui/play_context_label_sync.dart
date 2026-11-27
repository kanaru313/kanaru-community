import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/chat_providers.dart';

/// Hands the localized name of the AI assistant to the player's queue source
/// ("AI assistant" / "Trợ lý AI"). It sits at the top of the shell, so it runs
/// before any tool call, whether or not the chat is open, and follows a
/// change of language.
class AiPlayContextLabelSync extends ConsumerStatefulWidget {
  const AiPlayContextLabelSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AiPlayContextLabelSync> createState() =>
      _AiPlayContextLabelSyncState();
}

class _AiPlayContextLabelSyncState
    extends ConsumerState<AiPlayContextLabelSync> {
  String? _sent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final label = AppLocalizations.of(context).aiChatPlayContextLabel;
    if (label == _sent) return;
    _sent = label;
    // After the frame: a provider must not change while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(aiPlayContextLabelProvider.notifier).set(label);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
