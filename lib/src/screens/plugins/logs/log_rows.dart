import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/plugin_logs_provider.dart';

/// "21:04" for an entry of today, "22/11" over "21:04" for an older one (the
/// log keeps seven days).
String logTimeLabel(DateTime time, DateTime now) {
  final t = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = '${two(t.hour)}:${two(t.minute)}';
  final today = t.year == now.year && t.month == now.month && t.day == now.day;
  return today ? clock : '${two(t.day)}/${two(t.month)}\n$clock';
}

/// What the run was about: the song title the run was asked for, else the
/// host of its last request; null when the entry holds neither.
String? logTarget(RunLogEvent event) {
  final query = event.query;
  if (query is Map && query['title'] is String) {
    final title = (query['title'] as String).trim();
    if (title.isNotEmpty) return '“$title”';
  }
  final request = event.requests.lastOrNull;
  if (request == null || request.host.isEmpty) return null;
  return '${request.host}${request.path}';
}

/// The reason of a failure kind in words; an unknown kind shows as written.
String logKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'rateLimited' => l10n.pluginsLogsKindRateLimited,
  'invalidResponse' => l10n.pluginsLogsKindInvalidResponse,
  'server' => l10n.pluginsLogsKindServer,
  'auth' => l10n.pluginsLogsKindAuth,
  'quota' => l10n.pluginsLogsKindQuota,
  'timeout' => l10n.pluginsLogsKindTimeout,
  'memory' => l10n.pluginsLogsKindMemory,
  'stack' => l10n.pluginsLogsKindStack,
  'outputTooLarge' => l10n.pluginsLogsKindOutputTooLarge,
  'internal' => l10n.pluginsLogsKindInternal,
  'network' => l10n.pluginsLogsKindNetwork,
  'unavailable' => l10n.pluginsLogsKindUnavailable,
  'unsupported' => l10n.pluginsLogsKindUnsupported,
  _ => l10n.pluginsLogsKindOther(kind),
};

/// One entry of the log: time at the start, then "script · target" and the
/// result under it (a failure in the error colour). Console lines, when the
/// run printed any, follow in a monospace line. Entries are read from the
/// log file, which holds them already redacted.
class LogEntryRow extends StatelessWidget {
  const LogEntryRow({super.key, required this.event, required this.now});

  final RunLogEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final target = logTarget(event);
    final job = event.script;
    final message = event.message;
    final result = !event.isFailure
        ? l10n.pluginsLogsResultOk
        : message == null || message.isEmpty
        ? l10n.pluginsLogsResultError(logKindLabel(l10n, event.kind))
        : l10n.pluginsLogsResultErrorWith(
            logKindLabel(l10n, event.kind),
            message,
          );
    final console = event.console.join('\n');
    return SetupRowFrame(
      leading: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: KSpace.x9),
        child: Text(
          logTimeLabel(event.time, now),
          style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      title: Text(
        target == null ? job : l10n.pluginsLogsJobTarget(job, target),
        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: event.isFailure ? TextStyle(color: scheme.error) : null,
          ),
          if (console.isNotEmpty)
            Text(
              console,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(
                fontFamily: KFont.mono,
                fontFamilyFallback: KFont.monoFallback,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
