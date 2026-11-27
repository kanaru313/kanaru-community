import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/plugin_package.dart';
import '../common/seekbar_facts.dart';
import '../page/details_info_row.dart';
import 'source_card.dart' show formatPackageSize;

/// "Dữ kiện tĩnh" of a seek bar package: what the zip holds, that it has no
/// code, which built-in style it draws on and its licence. Read from the
/// package, never from the plugin's own words.
class SeekbarFactsBlock extends StatelessWidget {
  const SeekbarFactsBlock({super.key, required this.package});

  final PluginPackage package;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final manifest = package.manifest;
    final spec = manifest.seekbar;
    final files = seekbarFilesText(l10n, package.assets.keys);
    return SetupSection(
      title: Text(l10n.pluginsPkgFacts),
      hint: l10n.pluginsPkgFactsHint,
      hintTooltip: l10n.pluginsPkgFactsHintTooltip,
      hintTitle: l10n.pluginsPkgFacts,
      children: [
        DetailsInfoRow(
          label: l10n.pluginsSkFactPackage,
          lines: [
            DetailLine(
              l10n.pluginsSkPackageSize(
                files,
                formatPackageSize(package.keptBytes),
              ),
            ),
          ],
        ),
        DetailsInfoRow(
          label: l10n.pluginsSkFactCode,
          lines: [DetailLine(l10n.pluginsSkCodeNone)],
        ),
        if (spec != null)
          DetailsInfoRow(
            label: l10n.pluginsSkFactBase,
            lines: [DetailLine(seekbarBaseFact(l10n, spec))],
          ),
        DetailsInfoRow(
          label: l10n.pluginsSkFactLicense,
          lines: [DetailLine(manifest.license)],
        ),
      ],
    );
  }
}
