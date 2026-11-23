import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/domain/online/source_prefs.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../../plugins/support/plugin_fixtures.dart';
import '../support/settings_host.dart';

const _mobile = Size(400, 3000);

LyricsSource _src(
  int n, {
  String? name,
  LyricsSourceOrigin origin = LyricsSourceOrigin.repo,
  SourceProblem? problem,
  DateTime? pausedUntil,
}) => LyricsSource(
  id: 'id-$n',
  name: name ?? 'Source $n',
  version: 3,
  origin: origin,
  enabled: defaultSourceEnabled(origin),
  problem: problem,
  pausedUntil: pausedUntil,
);

/// The installed lyrics plugins as the real provider builds them: the saved
/// prefs decide order and switches, the plugin state is given.
List<Override> _sources(List<LyricsSource> installed, {bool loaded = true}) => [
  lyricsSourcesLoadedProvider.overrideWithValue(loaded),
  lyricsSourcesProvider.overrideWith(
    (ref) =>
        applySourcePrefs(ref.watch(lyricsOnlineSourcesProvider), installed),
  ),
];

Future<SettingsHarness> _open(
  WidgetTester tester,
  List<LyricsSource> installed, {
  Size size = _mobile,
  double textScale = 1,
  String location = SettingsPaths.lyrics,
  bool reduceMotion = false,
}) {
  final fixture = StoreFixture();
  return pumpPlugins(
    tester,
    fixture,
    location: location,
    size: size,
    textScale: textScale,
    reduceMotion: reduceMotion,
    overrides: _sources(installed),
  );
}

/// Where the top page is, also after a push.
String _location(SettingsHarness h) =>
    h.router.routerDelegate.currentConfiguration.last.matchedLocation;

Finder _sourceRows() => find.descendant(
  of: find.byType(ReorderableToggleList<String>),
  matching: find.byType(KSwitchRow),
);

Finder _switchOf(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(KSwitchRow)),
  matching: find.byType(KSwitch),
);

List<Object?>? _saved(SettingsHarness h) =>
    h.store.read('lyrics.online_sources') as List<Object?>?;

void main() {
  testWidgets('no lyrics plugin: only the Add row, no count', (tester) async {
    final h = await _open(tester, const []);
    expect(find.text('Online sources'), findsOneWidget);
    expect(find.textContaining(' sources on'), findsNothing);
    expect(_sourceRows(), findsNothing);
    expect(find.text('Add an online lyrics source'), findsOneWidget);
    await tester.tap(find.text('Add an online lyrics source'));
    await tester.pumpAndSettle();
    expect(_location(h), '/settings/plugins');
  });

  testWidgets('while the sources load there are no rows and no empty state', (
    tester,
  ) async {
    final fixture = StoreFixture();
    await pumpPlugins(
      tester,
      fixture,
      location: SettingsPaths.lyrics,
      size: _mobile,
      overrides: _sources([_src(1)], loaded: false),
    );
    expect(_sourceRows(), findsNothing);
    expect(find.textContaining(' sources on'), findsNothing);
    expect(find.textContaining('turn one on below'), findsNothing);
  });

  testWidgets('a repository source starts on and says its version', (
    tester,
  ) async {
    await _open(tester, [_src(1, name: 'LRCLIB')]);
    expect(find.text('LRCLIB'), findsOneWidget);
    expect(find.text('Plugin · v3'), findsOneWidget);
    expect(find.text('1 / 1 sources on'), findsOneWidget);
    expect(
      tester.getSemantics(_switchOf('LRCLIB')),
      isSemantics(hasToggledState: true, isToggled: true, hasTapAction: true),
    );
    expect(find.textContaining('turn one on below'), findsNothing);
  });

  testWidgets('a file or link install is off and says when it is searched', (
    tester,
  ) async {
    await _open(tester, [
      _src(1, name: 'Filed', origin: LyricsSourceOrigin.file),
      _src(2, name: 'Linked', origin: LyricsSourceOrigin.link),
    ]);
    expect(
      find.text('Installed from a file · v3 · only searched when you tap'),
      findsOneWidget,
    );
    expect(
      find.text('Installed from a link · v3 · only searched when you tap'),
      findsOneWidget,
    );
    expect(find.text('0 / 2 sources on'), findsOneWidget);
    expect(
      tester.getSemantics(_switchOf('Filed')),
      isSemantics(hasToggledState: true, isToggled: false, hasTapAction: true),
    );
    // Nothing is on: the auto search row says so.
    expect(
      find.textContaining('No lyrics source is on · turn one on below'),
      findsOneWidget,
    );
  });

  testWidgets('switching a source saves the list and says so', (tester) async {
    final fixture = StoreFixture();
    final h = await pumpPlugins(
      tester,
      fixture,
      location: SettingsPaths.lyrics,
      size: _mobile,
      overrides: _sources([_src(1, name: 'Zing'), _src(2, name: 'Other')]),
    );
    await tester.tap(_switchOf('Zing'));
    await tester.pumpAndSettle();
    expect(_saved(h), [
      {'id': 'id-1', 'on': false},
      {'id': 'id-2', 'on': true},
    ]);
    expect(find.text('Zing: off · only searched when you tap'), findsOneWidget);
    expect(find.text('1 / 2 sources on'), findsOneWidget);
    await tester.tap(_switchOf('Zing'));
    await tester.pumpAndSettle();
    expect(find.text('Zing: on for automatic search'), findsOneWidget);
    expect((_saved(h)!.first! as Map)['on'], isTrue);
  });

  testWidgets('the last source can be switched off too', (tester) async {
    final h = await _open(tester, [_src(1, name: 'Zing')]);
    await tester.tap(find.text('Zing'));
    await tester.pumpAndSettle();
    expect(_saved(h), [
      {'id': 'id-1', 'on': false},
    ]);
    expect(find.text('0 / 1 sources on'), findsOneWidget);
  });

  testWidgets('dragging a handle saves the new order', (tester) async {
    final h = await _open(tester, [
      _src(1, name: 'Alpha'),
      _src(2, name: 'Beta'),
      _src(3, name: 'Gamma'),
    ]);
    final handle = find.byTooltip('Drag to reorder').first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      [for (final p in _saved(h)!) (p! as Map)['id']],
      ['id-2', 'id-1', 'id-3'],
    );
    expect(
      tester.getTopLeft(find.text('Beta')).dy,
      lessThan(tester.getTopLeft(find.text('Alpha')).dy),
    );
  });

  group('problem lines', () {
    testWidgets('needs setup, paused and broken, each in the error colour', (
      tester,
    ) async {
      await _open(tester, [
        _src(1, name: 'Keyed', problem: SourceProblem.needsConfig),
        _src(
          2,
          name: 'Slow',
          problem: SourceProblem.paused,
          pausedUntil: DateTime(2026, 11, 23, 21, 5),
        ),
        _src(3, name: 'Bad', problem: SourceProblem.broken),
      ]);
      expect(
        find.text('Needs setup · open the plugin page to fill it in'),
        findsOneWidget,
      );
      expect(find.text('Paused until 9:05 PM'), findsOneWidget);
      expect(
        find.text('Broken package · open the plugin page'),
        findsOneWidget,
      );
      final scheme = Theme.of(tester.element(find.text('Keyed'))).colorScheme;
      final line = tester.widget<Text>(find.text('Paused until 9:05 PM'));
      expect(line.style?.color, scheme.error);
    });

    testWidgets('tapping the line opens the plugin page, not the switch', (
      tester,
    ) async {
      final h = await _open(tester, [
        _src(1, name: 'Keyed', problem: SourceProblem.needsConfig),
      ]);
      await tester.tap(
        find.text('Needs setup · open the plugin page to fill it in'),
      );
      await tester.pump();
      expect(_saved(h), isNull);
      expect(_location(h), '/settings/plugins/p/id-1');
    });

    testWidgets('the line is announced as a button', (tester) async {
      await _open(tester, [
        _src(1, name: 'Bad', problem: SourceProblem.broken),
      ]);
      expect(
        tester.getSemantics(find.text('Broken package · open the plugin page')),
        isSemantics(
          label: 'Broken package · open the plugin page',
          isButton: true,
          hasTapAction: true,
        ),
      );
    });
  });

  testWidgets('16 sources render and scroll', (tester) async {
    await _open(tester, [for (var i = 1; i <= 16; i++) _src(i)]);
    expect(find.text('16 / 16 sources on'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long names at 200 % text do not overflow', (tester) async {
    await _open(tester, [
      _src(
        1,
        name: 'Một nguồn lời có cái tên rất dài để thử xuống dòng ở cỡ chữ lớn',
        problem: SourceProblem.needsConfig,
      ),
      _src(2, name: 'Another extraordinarily long lyrics source name'),
    ], textScale: 2);
    expect(tester.takeException(), isNull);
  });

  group('auto search switch', () {
    testWidgets('is on by default and writes lyrics.auto_search', (
      tester,
    ) async {
      final h = await _open(tester, [_src(1)]);
      final row = find.ancestor(
        of: find.text('Find lyrics for songs without any'),
        matching: find.byType(KSwitchRow),
      );
      final sw = find.descendant(of: row, matching: find.byType(KSwitch));
      expect(
        tester.getSemantics(sw),
        isSemantics(hasToggledState: true, isToggled: true, hasTapAction: true),
      );
      await tester.tap(sw);
      await tester.pumpAndSettle();
      expect(h.store.read('lyrics.auto_search'), false);
    });

    testWidgets('says when no source is on', (tester) async {
      await _open(tester, const []);
      expect(
        find.text(
          'Searches the enabled lyrics sources when a song has no lyrics on '
          'this device.\nNo lyrics source is on · turn one on below',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('ⓘ only on the section title, none on rows', (tester) async {
    await _open(tester, [_src(1), _src(2)]);
    expect(byIconButton('About Online sources'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ReorderableToggleList<String>),
        matching: find.byType(KHelpIcon),
      ),
      findsNothing,
    );
    await tester.tap(byIconButton('About Online sources'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Order of the search'), findsOneWidget);
  });

  group('deep link', () {
    const small = Size(400, 600);
    Future<void> settle(WidgetTester tester) async {
      await tester.pump(KMotion.focusSettle);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    /// The section is built lazily: it exists only once the page scrolled.
    bool pulsing(WidgetTester tester) {
      final pulse = find.byType(SetupSectionPulse);
      return pulse.evaluate().isNotEmpty &&
          tester.state<SetupSectionPulseState>(pulse).isPulsing;
    }

    double offset(WidgetTester tester) => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;

    testWidgets('?focus=sources scrolls to the section and pulses it', (
      tester,
    ) async {
      await _open(
        tester,
        [for (var i = 1; i <= 8; i++) _src(i)],
        size: small,
        location: '/settings/lyrics?focus=sources',
      );
      expect(offset(tester), 0);
      var pulsed = false;
      await tester.pump(KMotion.focusSettle);
      for (var i = 0; i < 60 && !pulsed; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        pulsed = pulsing(tester);
      }
      expect(pulsed, isTrue);
      expect(offset(tester), greaterThan(0));
      expect(tester.getTopLeft(find.text('Online sources')).dy, lessThan(600));
      await tester.pumpAndSettle();
    });

    testWidgets('with animations off it scrolls but does not pulse', (
      tester,
    ) async {
      await _open(
        tester,
        [for (var i = 1; i <= 8; i++) _src(i)],
        size: small,
        location: '/settings/lyrics?focus=sources',
        reduceMotion: true,
      );
      await settle(tester);
      expect(find.byType(SetupSectionPulse), findsOneWidget);
      expect(pulsing(tester), isFalse);
      expect(offset(tester), greaterThan(0));
    });

    testWidgets('without the param the page stays at the top', (tester) async {
      await _open(tester, [for (var i = 1; i <= 8; i++) _src(i)], size: small);
      await settle(tester);
      expect(offset(tester), 0);
    });
  });

  testWidgets('semantics tree builds without errors', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, [_src(1), _src(2, problem: SourceProblem.broken)]);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
