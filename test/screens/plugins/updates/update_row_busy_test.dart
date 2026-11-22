import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/plugins/state/updates_provider.dart';
import 'package:kanaru/src/screens/plugins/store/store_actions.dart';
import 'package:kanaru/src/screens/plugins/store/store_rows.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

StoreRowView _row(String id, String name) => StoreRowView(
  installId: id,
  name: name,
  author: 'kanaru313',
  kind: PluginKind.lyrics,
  state: StoreItemState.updateAvailable,
);

void main() {
  testWidgets('an updating row spins and locks; the other row stays usable', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updatingIdsProvider.overrideWithValue({'a'}),
          pluginIconProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                for (final (id, name) in [('a', 'First'), ('b', 'Second')])
                  UpdateRow(
                    row: _row(id, name),
                    actions: StoreActions(
                      onUpdate: (_, row) => tapped.add(row.installId),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Updating…'), findsOneWidget);
    await tester.tap(find.text('Updating…'));
    await tester.tap(find.text('Update'));
    await tester.pump();
    expect(tapped, ['b']);
  });
}
