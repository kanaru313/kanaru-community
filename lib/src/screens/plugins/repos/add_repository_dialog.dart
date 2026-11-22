import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/repo_results.dart';
import '../../../plugins/state/store_ops.dart';
import '../common/plugin_labels.dart';

/// Opens the "Thêm repository" dialog, with [initialUrl] already in the
/// field (the install-from-link flow hands over a `plugins.json` link). On
/// success it closes and says "Đã thêm {tên} · n plugin".
Future<void> showAddRepositoryDialog(
  BuildContext context, {
  String initialUrl = '',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final added = await showKDialog<({String name, int count})>(
    context,
    maxWidth: KLayout.dialogWide - 100,
    builder: (_) => _AddRepositoryDialog(initialUrl: initialUrl),
  );
  if (added == null) return;
  showAppSnackBarOn(messenger, l10n.pluginsAddedRepo(added.count, added.name));
}

class _AddRepositoryDialog extends ConsumerStatefulWidget {
  const _AddRepositoryDialog({required this.initialUrl});

  final String initialUrl;

  @override
  ConsumerState<_AddRepositoryDialog> createState() => _AddDialogState();
}

class _AddDialogState extends ConsumerState<_AddRepositoryDialog> {
  late final _url = TextEditingController(text: widget.initialUrl);
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _url.text.trim();
    if (_loading || text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    final ops = ref.read(storeOpsProvider);
    final result = await ops.add(text);
    if (!mounted) return;
    switch (result) {
      case RepoAddFailed():
        setState(() {
          _loading = false;
          _error = addRepoFailureText(l10n, result);
        });
      case RepoAdded(:final repoId):
        final repo = await ops.describe(repoId);
        if (!mounted) return;
        Navigator.of(context)
            .pop((name: repo?.name ?? text, count: repo?.pluginCount ?? 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        title: Text(l10n.pluginsAddRepository),
        content: KTextFieldRow(
          label: l10n.pluginsAddDialogUrlLabel,
          controller: _url,
          hint: l10n.pluginsAddDialogUrlHint,
          helper: l10n.pluginsAddDialogHelper,
          error: _error,
          enabled: !_loading,
          autofocus: true,
          keyboard: TextInputType.url,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.pluginsCancel),
          ),
          ListenableBuilder(
            listenable: _url,
            builder: (context, _) => FilledButton(
              onPressed: _loading || _url.text.trim().isEmpty ? null : _submit,
              child: _loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: KSpace.x2,
                      children: [
                        const SizedBox.square(
                          dimension: KIconSize.sm,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        Text(l10n.pluginsAddDialogLoading),
                      ],
                    )
                  : Text(l10n.pluginsAddDialogConfirm),
            ),
          ),
        ],
      ),
    );
  }
}
