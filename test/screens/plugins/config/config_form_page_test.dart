import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';

import '../../../plugins/domain/plugin_test_support.dart';
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';
import 'support/form_finders.dart';

final _config = parseOk(
  withConfig({
    'host': {'title': 'Host', 'mode': 'input', 'format': 'text'},
  }),
);

Future<void> _pump(
  WidgetTester tester,
  PluginPageData data, {
  Size size = const Size(400, 2400),
}) => pumpPlugins(
  tester,
  StoreFixture(),
  location: pagePath,
  size: size,
  overrides: pageOverrides(AsyncData(data)),
);

void main() {
  for (final (shell, size) in [
    ('narrow', const Size(400, 2400)),
    ('wide', const Size(1400, 2400)),
  ]) {
    group(shell, () {
      testWidgets('the page replaces the placeholder with the form, unlocked', (
        tester,
      ) async {
        await _pump(tester, pageData(manifest: _config), size: size);
        expect(find.text('The plugin’s settings'), findsOneWidget);
        expect(enabledBox(tester, 'Host'), isTrue);
      });

      for (final (name, data) in [
        (
          'a broken package',
          pageData(manifest: _config, alerts: {PluginAlert.broken}),
        ),
        (
          'a package that is gone',
          pageData(
            manifest: _config,
            alerts: {PluginAlert.packageMissing},
            missing: RestoreAction.download,
          ),
        ),
        (
          'a package to pick again',
          pageData(
            manifest: _config,
            alerts: {PluginAlert.reinstallFromFile},
            missing: RestoreAction.pickFile,
          ),
        ),
        (
          'an update of this plugin under way',
          pageData(manifest: _config, updating: true),
        ),
      ]) {
        testWidgets('the form is locked for $name', (tester) async {
          await _pump(tester, data, size: size);
          expect(enabledBox(tester, 'Host'), isFalse);
        });
      }

      testWidgets(
        'nothing else locks it: a missing setting, a waiting update',
        (tester) async {
          await _pump(
            tester,
            pageData(
              manifest: _config,
              alerts: {PluginAlert.missingRequiredConfig},
              missingConfig: ['Host'],
              update: const PluginPageUpdate(
                version: 4,
                needsReview: true,
                newHosts: [],
                repoId: 1,
              ),
            ),
            size: size,
          );
          expect(enabledBox(tester, 'Host'), isTrue);
        },
      );
    });
  }
}
