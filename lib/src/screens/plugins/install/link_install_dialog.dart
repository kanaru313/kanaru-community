import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/install_ops.dart';
import '../repos/add_repository_dialog.dart';
import 'package_controller.dart';
import 'package_flow.dart';

/// What the link dialog decided.
sealed class LinkChoice {
  const LinkChoice(this.url);
  final String url;
}

/// Download this package and show the install screen.
final class LinkInstall extends LinkChoice {
  const LinkInstall(super.url);
}

/// The link is a `plugins.json`: add it as a repository.
final class LinkAddRepository extends LinkChoice {
  const LinkAddRepository(super.url);
}

/// Whether [text] is an absolute http(s) address with a host.
bool isPackageLink(String text) {
  final uri = Uri.tryParse(text.trim());
  return uri != null &&
      uri.hasAuthority &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}

/// Whether the link points at a repository list, not a package.
bool isCatalogLink(String text) {
  final uri = Uri.tryParse(text.trim());
  return uri != null && uri.path.toLowerCase().endsWith('/plugins.json');
}

/// "Cài từ đường dẫn…": asks for the link, then opens the install screen or
/// the add-repository dialog (a `plugins.json` link).
Future<void> installFromLink(BuildContext context, InstallOps ops) async {
  final choice = await showKDialog<LinkChoice>(
    context,
    maxWidth: KLayout.dialogWide - 100,
    builder: (_) => const LinkInstallDialog(),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case LinkAddRepository(:final url):
      await showAddRepositoryDialog(context, initialUrl: url);
    case LinkInstall(:final url):
      await runPackageFlow(
        context,
        ops: ops,
        start: () => ops.prepareLink(url),
        subject: PackageSubject(url, named: false),
      );
  }
}

class LinkInstallDialog extends StatefulWidget {
  const LinkInstallDialog({super.key});

  @override
  State<LinkInstallDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkInstallDialog> {
  final _url = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _url.text.trim();
    if (text.isEmpty) return;
    if (isCatalogLink(text) && isPackageLink(text)) {
      Navigator.of(context).pop(LinkAddRepository(text));
    } else if (isPackageLink(text)) {
      Navigator.of(context).pop(LinkInstall(text));
    } else {
      setState(
        () => _error = AppLocalizations.of(context).pluginsLinkErrInvalid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.pluginsLinkTitle),
      content: ListenableBuilder(
        listenable: _url,
        builder: (context, _) => KTextFieldRow(
          label: l10n.pluginsLinkLabel,
          controller: _url,
          hint: l10n.pluginsLinkHint,
          helper: isCatalogLink(_url.text)
              ? l10n.pluginsLinkHelperCatalog
              : l10n.pluginsLinkHelper,
          error: _error,
          autofocus: true,
          keyboard: TextInputType.url,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.pluginsCancel),
        ),
        ListenableBuilder(
          listenable: _url,
          builder: (context, _) => FilledButton(
            onPressed: _url.text.trim().isEmpty ? null : _submit,
            child: Text(
              isCatalogLink(_url.text)
                  ? l10n.pluginsLinkAddRepo
                  : l10n.pluginsLinkContinue,
            ),
          ),
        ),
      ],
    );
  }
}
