import 'dart:async';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/install/repo_results.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/screens/plugins/repos/add_repository_dialog.dart';
import 'package:kanaru/src/screens/plugins/repos/repositories_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart'
    show FilledButton, ListView, TextButton, TextField;

import '../../../support/icon_button_finders.dart';
import '../support/plugin_fixtures.dart';

const _repos = [
  RepoView(
    id: 1,
    name: 'Nhạc Việt Plugins',
    url: 'https://nhacviet.example.org/plugins.json?token=abc',
    pluginCount: 13,
  ),
  RepoView(
    id: 2,
    name: 'Broken',
    url: 'https://broken.example.org/plugins.json',
    pluginCount: 0,
    errorKind: 'network',
  ),
];

const _path = '/settings/plugins/repositories';

StoreFixture _fixture({FakeStoreOps? ops}) =>
    StoreFixture(repos: _repos, ops: ops);

Future<void> _openAdd(WidgetTester tester) async {
  await tester.tap(find.byType(KFab));
  await tester.pumpAndSettle();
}

Finder get _addButton => find.widgetWithText(FilledButton, 'Add');

void main() {
  for (final (name, size) in [
    ('narrow', const Size(400, 900)),
    ('wide', const Size(1400, 900)),
  ]) {
    testWidgets('$name: rows show name, URL as entered, count or error', (
      tester,
    ) async {
      final fixture = _fixture();
      await pumpPlugins(tester, fixture, location: _path, size: size);
      expect(find.text('Repositories'), findsWidgets);
      expect(find.text('Nhạc Việt Plugins'), findsOneWidget);
      // The address is shown whole, query token included.
      expect(
        find.text('https://nhacviet.example.org/plugins.json?token=abc'),
        findsOneWidget,
      );
      expect(find.text('13 plugins'), findsOneWidget);
      expect(find.text('Last load failed: network error'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(fixture.ops.refreshed, [2]);
      expect(
        find.text(
          'Removing a repository keeps the plugins installed from it, '
          'but they no longer get updates.',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('the header refreshes every repository', (tester) async {
    final fixture = _fixture();
    await pumpPlugins(tester, fixture, location: _path);
    await tester.tap(byIconButton('Refresh all'));
    expect(fixture.ops.refreshAlls, 1);
  });

  testWidgets('the add button is an icon-only FAB named Add repository', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPlugins(tester, _fixture(), location: _path);
    expect(tester.getSize(find.byType(KFab)), const Size(56, 56));
    expect(find.bySemanticsLabel('Add repository'), findsOneWidget);
    expect(find.text('Add repository'), findsNothing);
    handle.dispose();
  });

  testWidgets('the last row stays reachable above the button', (tester) async {
    final many = [
      for (var i = 1; i <= 15; i++)
        RepoView(
          id: i,
          name: 'Repo $i',
          url: 'https://r$i.example.org/p',
          pluginCount: i,
        ),
    ];
    await pumpPlugins(
      tester,
      StoreFixture(repos: many),
      location: _path,
      size: const Size(400, 700),
    );
    await tester.drag(find.byType(KPage), const Offset(0, -4000));
    await tester.pumpAndSettle();
    final fab = tester.getRect(find.byType(KFab));
    final last = tester.getRect(find.text('Repo 15'));
    expect(last.bottom, lessThanOrEqualTo(fab.top));
  });

  testWidgets('on a wide window the button sits at the end of the column', (
    tester,
  ) async {
    await pumpPlugins(
      tester,
      _fixture(),
      location: _path,
      size: const Size(1600, 900),
    );
    final fab = tester.getRect(find.byType(KFab));
    final column = tester.getRect(find.byType(ListView));
    // Inside the centred page column, not at the window edge.
    expect(fab.right, lessThanOrEqualTo(column.right));
    expect(fab.right, greaterThan(column.right - 80));
    expect(fab.right, lessThan(1600 - 100));
  });

  group('add dialog', () {
    testWidgets('Add is disabled while the field is empty', (tester) async {
      await pumpPlugins(tester, _fixture(), location: _path);
      await _openAdd(tester);
      expect(tester.widget<FilledButton>(_addButton).onPressed, isNull);
      expect(
        find.text(
          'The address of the plugins.json file. Must be https, except for '
          'machines on your home network (localhost, 192.168.x…).',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'https://a.example/p');
      await tester.pump();
      expect(tester.widget<FilledButton>(_addButton).onPressed, isNotNull);
    });

    testWidgets('an error replaces the helper line', (tester) async {
      final ops = FakeStoreOps()
        ..onAdd = (_) => const RepoAddFailed(RepoError.duplicate);
      await pumpPlugins(tester, _fixture(ops: ops), location: _path);
      await _openAdd(tester);
      await tester.enterText(find.byType(TextField), 'https://a.example/p');
      await tester.pump();
      await tester.tap(_addButton);
      await tester.pumpAndSettle();
      expect(find.text('This repository is already added'), findsOneWidget);
      expect(
        find.textContaining('The address of the plugins.json'),
        findsNothing,
      );
      // The dialog stays and keeps what was typed.
      expect(find.text('https://a.example/p'), findsOneWidget);
    });

    testWidgets('the service result maps to the six spec lines', (
      tester,
    ) async {
      final cases = <RepoAddFailed, String>{
        const RepoAddFailed(RepoError.needsHttps):
            'Public addresses need https',
        const RepoAddFailed(RepoError.invalidUrl): 'Invalid URL',
        const RepoAddFailed(RepoError.network):
            'Couldn\'t load the list: network error',
        const RepoAddFailed(RepoError.notACatalog):
            'The file is not a valid plugin list',
        const RepoAddFailed(RepoError.badStatus):
            'No plugin list found at this address',
        const RepoAddFailed(RepoError.blocked, reason: AddressProblem.userInfo): 'This address is blocked: the address must not contain a user name or password',
      };
      final ops = FakeStoreOps();
      await pumpPlugins(tester, _fixture(ops: ops), location: _path);
      await _openAdd(tester);
      await tester.enterText(find.byType(TextField), 'https://a.example/p');
      await tester.pump();
      for (final entry in cases.entries) {
        ops.onAdd = (_) => entry.key;
        await tester.tap(_addButton);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget, reason: entry.value);
      }
    });

    testWidgets('while loading the field and Cancel are locked', (
      tester,
    ) async {
      final gate = Completer<void>();
      final ops = FakeStoreOps()..addGate = gate.future;
      await pumpPlugins(tester, _fixture(ops: ops), location: _path);
      await _openAdd(tester);
      await tester.enterText(find.byType(TextField), 'https://a.example/p');
      await tester.pump();
      await tester.tap(_addButton);
      await tester.pump();
      expect(find.text('Loading…'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('success closes and says what was added', (tester) async {
      final ops = FakeStoreOps();
      await pumpPlugins(tester, _fixture(ops: ops), location: _path);
      await _openAdd(tester);
      await tester.enterText(find.byType(TextField), 'https://a.example/p');
      await tester.pump();
      await tester.tap(_addButton);
      await tester.pumpAndSettle();
      expect(ops.added, ['https://a.example/p']);
      expect(find.text('Added Nhạc Việt Plugins · 6 plugins'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a handed-over link opens the dialog prefilled', (
      tester,
    ) async {
      await pumpPlugins(tester, _fixture(), location: _path);
      unawaited(
        showAddRepositoryDialog(
          tester.element(find.byType(RepositoriesPage)),
          initialUrl: 'https://raw.example.org/plugins.json',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('https://raw.example.org/plugins.json'), findsOneWidget);
      expect(tester.widget<FilledButton>(_addButton).onPressed, isNotNull);
    });
  });

  group('remove', () {
    testWidgets('asks first, then removes', (tester) async {
      final fixture = _fixture();
      await pumpPlugins(tester, fixture, location: _path);
      await tester.tap(byIconButton('Remove repository Nhạc Việt Plugins'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Nhạc Việt Plugins?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fixture.ops.removed, isEmpty);
      await tester.tap(byIconButton('Remove repository Nhạc Việt Plugins'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(fixture.ops.removed, [1]);
    });

    testWidgets('a failed removal is said', (tester) async {
      final ops = FakeStoreOps()..removeResult = RepoRemoveResult.failed;
      await pumpPlugins(tester, _fixture(ops: ops), location: _path);
      await tester.tap(byIconButton('Remove repository Broken'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn\'t remove Broken'), findsOneWidget);
    });
  });
}
