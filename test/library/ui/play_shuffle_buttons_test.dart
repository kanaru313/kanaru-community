import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/browse/play_shuffle_buttons.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildKanaruTheme(brightness: Brightness.light),
  locale: const Locale('en'),
  localizationsDelegates: [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

PlayShuffleButtons _buttons({
  VoidCallback? onPlay,
  VoidCallback? onShuffle,
  bool compact = true,
  bool labelled = false,
  String label = 'Play all',
}) => PlayShuffleButtons(
  playLabel: label,
  onPlay: onPlay,
  onShuffle: onShuffle,
  compact: compact,
  labelled: labelled,
);

Finder _node(String label) => find.bySemanticsLabel(label);

SemanticsFinder _button(String label) => find.semantics.byLabel(label);

void main() {
  group('list bar (compact)', () {
    testWidgets('play and shuffle are labelled buttons that fire', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var played = 0;
      var shuffled = 0;
      await tester.pumpWidget(
        _host(_buttons(onPlay: () => played++, onShuffle: () => shuffled++)),
      );
      for (final label in ['Play all', 'Shuffle']) {
        expect(
          tester.getSemantics(_node(label)),
          isSemantics(
            label: label,
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      }
      tester.semantics.tap(_button('Play all'));
      tester.semantics.tap(_button('Shuffle'));
      expect([played, shuffled], [1, 1]);
      // Icon only: the label is not drawn.
      expect(find.text('Play all'), findsNothing);
      handle.dispose();
    });

    testWidgets('a null callback disables only its button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_buttons(onShuffle: () {})));
      expect(
        tester.getSemantics(_node('Play all')),
        isSemantics(
          label: 'Play all',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(
        tester.getSemantics(_node('Shuffle')),
        isSemantics(
          label: 'Shuffle',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });
  });

  testWidgets('hero row: labelled play with its text, and shuffle', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var played = 0;
    var shuffled = 0;
    await tester.pumpWidget(
      _host(
        _buttons(
          compact: false,
          labelled: true,
          label: 'Play',
          onPlay: () => played++,
          onShuffle: () => shuffled++,
        ),
      ),
    );
    expect(find.text('Play'), findsOneWidget);
    tester.semantics.tap(_button('Play'));
    await tester.tap(find.byTooltip('Shuffle'));
    expect([played, shuffled], [1, 1]);
    handle.dispose();
  });
}
