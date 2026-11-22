import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_ops.dart';
import '../../../plugins/state/store_view_models.dart';
import '../common/plugin_labels.dart';

/// The band above the list when a repository could not be loaded: one repo
/// failed (its name, why, when the saved list is from), several failed, or
/// every repository failed for lack of a network. Null when all is well.
class StoreBanner extends ConsumerWidget {
  const StoreBanner({super.key, required this.repos});

  final List<RepoView> repos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = [
      for (final repo in repos)
        if (repo.errorKind != null) repo,
    ];
    if (failed.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final ops = ref.read(storeOpsProvider);
    // One failing repository is named; "offline" needs two or more, all down.
    final offline =
        repos.length >= 2 &&
        failed.length == repos.length &&
        failed.every((r) => isNetworkFailure(r.errorKind));
    final KInlineNotice notice;
    if (offline) {
      notice = KInlineNotice(
        icon: KIcons.offline,
        tone: KInlineNoticeTone.errorFilled,
        title: l10n.pluginsOfflineTitle,
        message: l10n.pluginsOfflineBody,
        actionLabel: l10n.pluginsRetry,
        onAction: ops.refreshAll,
      );
    } else if (failed.length == 1) {
      final repo = failed.single;
      final at = repo.refreshedAt;
      notice = KInlineNotice(
        icon: KIcons.warning,
        tone: KInlineNoticeTone.errorFilled,
        title: l10n.pluginsRepoFailedOne(
          repo.name,
          repoLoadReason(l10n, repo.errorKind),
        ),
        message: at == null
            ? ''
            : l10n.pluginsRepoShowingSaved(
                DateFormat.Hm(l10n.localeName)
                    .format(DateTime.fromMillisecondsSinceEpoch(at)),
              ),
        actionLabel: l10n.pluginsRetry,
        onAction: () => ops.refresh(repo.id),
      );
    } else {
      notice = KInlineNotice(
        icon: KIcons.warning,
        tone: KInlineNoticeTone.errorFilled,
        title: l10n.pluginsRepoFailedMany(failed.length),
        message: '',
        actionLabel: l10n.pluginsRetry,
        onAction: ops.refreshAll,
      );
    }
    return notice;
  }
}
