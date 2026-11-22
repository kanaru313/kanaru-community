import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/config_form_provider.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import 'config_env.dart';
import 'config_field_tile.dart';

/// "Cài đặt của plugin": one section holding an editor per field of the
/// plugin's manifest, in manifest order. Everything saves by itself (no
/// button, no "saved" notice); a refused value says why under its field.
/// [locked] dims the form and keeps it out of reach (a broken package, an
/// update of this plugin under way). While the values are read the card is
/// an empty 56 dp one; an unreadable store says so with [Thử lại].
class ConfigForm extends ConsumerWidget {
  const ConfigForm({super.key, required this.installId, this.locked = false});

  final String installId;
  final bool locked;

  /// Height of the card while the values are read.
  static const double readingHeight = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(configFormProvider(installId));
    final ops = ref.watch(configOpsProvider);
    final env = ConfigEnv(installId: installId, ops: ops, locked: locked);
    return SetupSection(
      title: Text(l10n.pluginsPageSettingsTitle),
      children: form.when(
        loading: () => const [SizedBox(height: readingHeight)],
        error: (error, stack) => [
          SetupRowFrame(
            title: Text(l10n.pluginsCfgReadFailed),
            trailing: TextButton(
              onPressed: () => ref.invalidate(pluginConfigProvider(installId)),
              child: Text(l10n.pluginsRetry),
            ),
          ),
        ],
        data: (data) => data == null
            ? const [SizedBox(height: readingHeight)]
            : [
                for (final field in data.fields)
                  ConfigFieldTile(
                    key: ValueKey(field.key),
                    field: field,
                    data: data,
                    env: env,
                  ),
              ],
      ),
    );
  }
}
