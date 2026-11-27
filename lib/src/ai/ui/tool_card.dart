import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/conversation/ai_message.dart';
import '../domain/conversation/parts.dart';
import 'tool_text.dart';

/// A tool the assistant called: folded to a header (icon, name, one-line
/// result, chevron) and opened to the arguments and the result. While the tool
/// runs the name reads "Đang chạy: …" and a spinner takes the chevron's place.
class ToolCard extends StatefulWidget {
  const ToolCard({super.key, required this.message});

  final AiMessage message;

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final call = widget.message.parts.whereType<ToolCallPart>().firstOrNull;
    final result = widget.message.parts.whereType<ToolResultPart>().firstOrNull;
    final running = widget.message.state == AiMessageState.running;
    final name = toolDisplayName(l10n, call?.name ?? result?.name ?? '');
    final resultText = result == null
        ? ''
        : result.content.whereType<TextPart>().map((p) => p.text).join();
    final summary = running ? '' : toolSummary(l10n, resultText);
    final instant = MediaQuery.disableAnimationsOf(context);
    final mobile = FormFactor.of(context) == FormFactor.mobile;

    final args = call == null ? '' : toolArgsPreview(call.args, call.rawArgs);
    final preview = toolResultPreview(resultText);

    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x2 + 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: KRadius.sm,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: KRadius.sm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                expanded: _open,
                child: InkWell(
                  onTap: () => setState(() => _open = !_open),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: mobile ? 48 : 44),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: KSpace.x2 + 2,
                        end: KSpace.x2,
                        top: KSpace.x1 + 2,
                        bottom: KSpace.x1 + 2,
                      ),
                      child: Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: KRadius.xs,
                            ),
                            child: SizedBox.square(
                              dimension: 28,
                              child: Icon(
                                toolIcon(call?.name ?? ''),
                                size: KIconSize.xs,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: KSpace.x3 - 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  running ? l10n.aiChatToolRunning(name) : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                if (summary.isNotEmpty)
                                  Text(
                                    summary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (running)
                            Padding(
                              padding: const EdgeInsets.all(KSpace.x2),
                              child: SizedBox.square(
                                dimension: 18,
                                // With animations off a still arc stands for
                                // "working"; the title says it too.
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  value: instant ? 0.3 : null,
                                ),
                              ),
                            )
                          else
                            AnimatedRotation(
                              turns: _open ? 0.5 : 0,
                              duration: instant ? Duration.zero : KMotion.fast,
                              child: Icon(
                                KIcons.collapse,
                                size: KIconSize.xs + 2,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_open)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 48,
                    end: KSpace.x3,
                    bottom: KSpace.x3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (args.isNotEmpty) _Block(l10n.aiChatToolParams, args),
                      if (preview.isNotEmpty)
                        _Block(l10n.aiChatToolResult, preview),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x1 + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: KSpace.x1 / 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: KRadius.xs,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KSpace.x2 + 2,
                vertical: KSpace.x2,
              ),
              child: Text(
                body,
                style: text.labelSmall?.copyWith(
                  fontFamily: KFont.mono,
                  fontFamilyFallback: KFont.monoFallback,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
