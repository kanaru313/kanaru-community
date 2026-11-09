import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_providers.dart';
import '../../screens/settings/state/appearance_settings.dart';
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
      themeMode: ref.watch(themeChoiceProvider).mode,
      locale: Locale(ref.watch(appLanguageProvider).name),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...registry.l10nDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
