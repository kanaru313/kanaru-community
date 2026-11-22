import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/screens/plugins/common/hosts_block.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester, HostsBlock block) => tester.pumpWidget(
  MaterialApp(
    theme: buildKanaruTheme(brightness: Brightness.light),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: block)),
  ),
);

void main() {
  testWidgets('no host and no typed address says there is none', (
    tester,
  ) async {
    await _pump(
      tester,
      const HostsBlock(hosts: [], consent: HostsConsent.install),
    );
    expect(find.text('No fixed address.'), findsOneWidget);
    expect(find.textContaining('you agree'), findsNothing);
  });

  testWidgets('a typed address alone still asks consent', (tester) async {
    await _pump(
      tester,
      const HostsBlock(
        hosts: [],
        endpointFields: ['Server'],
        consent: HostsConsent.install,
      ),
    );
    expect(find.text('Address you enter in Server'), findsOneWidget);
    expect(find.text('No fixed address.'), findsNothing);
    expect(find.textContaining('you agree'), findsOneWidget);
  });

  testWidgets('twelve hosts and large text still lay out', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HostsBlock(
                hosts: [for (var i = 0; i < 12; i++) 'host$i.example.com'],
                newHosts: const ['*.cdn.example.com'],
                consent: HostsConsent.update,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('NEW'), findsOneWidget);
  });
}
