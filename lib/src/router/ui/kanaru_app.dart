import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_providers.dart';
import '../state/router_provider.dart';

/// Root widget: theme, localization and the router.
class KanaruApp extends ConsumerWidget {
  const KanaruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(extensionRegistryProvider);
    return MaterialApp.router(
      title: 'Kanaru',
      theme: buildKanaruTheme(brightness: Brightness.light),
      darkTheme: buildKanaruTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...registry.l10nDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
