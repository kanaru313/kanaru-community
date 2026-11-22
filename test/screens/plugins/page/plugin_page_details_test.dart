import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';

import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';

int _ms(int y, int m, int d) => DateTime(y, m, d, 12).millisecondsSinceEpoch;

Future<void> _pump(
  WidgetTester tester,
  PluginPageData data, {
  Size size = const Size(400, 2400),
  double textScale = 1,
}) async {
  await pumpPlugins(
    tester,
    StoreFixture(
      repos: const [
        RepoView(
          id: 1,
          name: 'Kanaru Plugins',
          url: repoAddress,
          pluginCount: 3,
        ),
      ],
    ),
    location: pagePath,
    size: size,
    textScale: textScale,
    overrides: pageOverrides(AsyncData(data)),
  );
}

void main() {
  for (final (shell, size) in [
    ('narrow', const Size(400, 2400)),
    ('wide', const Size(1400, 2400)),
  ]) {
    testWidgets('$shell: a repository plugin lists where it came from', (
      tester,
    ) async {
      await _pump(
        tester,
        pageData(
          row: pageRow(
            hosts: ['music.example.com', '*.googlevideo.com'],
            installedAt: _ms(2026, 11, 2),
            updatedAt: _ms(2026, 11, 10),
          ),
        ),
        size: size,
      );
      expect(find.text('Installed from'), findsOneWidget);
      expect(find.text('Repo: Kanaru Plugins'), findsOneWidget);
      expect(find.text(repoAddress), findsOneWidget);
      expect(find.text('Sends data to'), findsOneWidget);
      expect(find.text('music.example.com'), findsOneWidget);
      expect(
        find.text('Every subdomain of googlevideo.com (*.googlevideo.com)'),
        findsOneWidget,
      );
      expect(find.text('02/11/2026 · updated 10/11/2026'), findsOneWidget);
      expect(find.text('Demo plugin'), findsOneWidget);
      expect(find.text('Plugin for lyrics · plugin API 2'), findsOneWidget);
    });
  }

  testWidgets('one date when it was installed and updated on one day', (
    tester,
  ) async {
    await _pump(
      tester,
      pageData(
        row: pageRow(
          installedAt: _ms(2026, 11, 2),
          updatedAt: _ms(2026, 11, 2),
        ),
      ),
    );
    expect(find.text('02/11/2026'), findsOneWidget);
  });

  testWidgets('a file install says it gets no updates', (tester) async {
    await _pump(tester, pageData(row: pageRow(origin: 'file')));
    expect(find.text('File: demo-3.zip'), findsOneWidget);
    expect(
      find.text(
        'This plugin was installed from a file, so it gets no updates. '
        'Remove it and install the new file.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a link install shows its name, address and sentence', (
    tester,
  ) async {
    await _pump(tester, pageData(row: pageRow(origin: 'link')));
    expect(find.text('Link: demo.zip'), findsOneWidget);
    expect(find.text('https://files.example.com/dl/demo.zip'), findsOneWidget);
    expect(
      find.textContaining('installed from a link, so it gets no updates'),
      findsOneWidget,
    );
  });

  testWidgets('address fields say what was entered or that nothing was', (
    tester,
  ) async {
    await _pump(
      tester,
      pageData(
        row: pageRow(hosts: const []),
        endpoints: const [
          PageEndpoint(label: 'Server', hosts: ['lyrics.home.lan']),
          PageEndpoint(label: 'Mirror', hosts: []),
        ],
      ),
    );
    expect(
      find.text('Address you enter in Server: lyrics.home.lan'),
      findsOneWidget,
    );
    expect(
      find.text('Address you enter in Mirror: (not entered)'),
      findsOneWidget,
    );
    expect(find.text('No fixed address.'), findsNothing);
    expect(
      find.textContaining('agree'),
      findsNothing,
      reason: 'no consent line',
    );
  });

  testWidgets('no hosts and no address field: no fixed address', (
    tester,
  ) async {
    await _pump(tester, pageData(row: pageRow(hosts: const [])));
    expect(find.text('No fixed address.'), findsOneWidget);
  });

  testWidgets('the description row is left out when there is none', (
    tester,
  ) async {
    await _pump(tester, pageData(manifest: pageManifest(description: '')));
    expect(find.text('Description'), findsNothing);
  });

  testWidgets('features that are not built are dimmed rows', (tester) async {
    await _pump(tester, pageData());
    for (final title in [
      'Static facts',
      'Source code',
      'Requests at once',
      'Time between requests',
      'Plugin’s own storage',
      'Lyrics saved from this source',
      'Log',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Coming soon'), findsWidgets);
    expect(find.text('Track and cover cache'), findsNothing);
  });

  testWidgets('a translate plugin has the AI tag and its own usage row', (
    tester,
  ) async {
    await _pump(
      tester,
      pageData(
        row: pageRow(kind: 'ai-translate', name: 'Gemini'),
      ),
    );
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Default translation service'), findsOneWidget);
    expect(find.text('Lyrics saved from this source'), findsNothing);
  });

  testWidgets('an author-less plugin and 200 % text still read', (
    tester,
  ) async {
    await _pump(tester, pageData(row: pageRow(author: null)), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Unknown author · version 3'), findsOneWidget);
  });
}
