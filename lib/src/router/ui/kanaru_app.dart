import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_providers.dart';
import '../../platform/state/window_close_provider.dart';
import '../../screens/settings/state/appearance_settings.dart';
import '../state/app_flush.dart';
import 'app_theme_provider.dart';
import '../state/router_provider.dart';

final _log = Logger('app.flush');

/// Root widget: theme, localization and the router. Also flushes pending state
/// when the app goes to the background and when it is asked to exit.
class KanaruApp extends ConsumerStatefulWidget {
  const KanaruApp({super.key});

  @override
  ConsumerState<KanaruApp> createState() => _KanaruAppState();
}

class _KanaruAppState extends ConsumerState<KanaruApp> {
  late final AppLifecycleListener _lifecycle;
  final _flusher = FlushCoordinator();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: _onState,
      onExitRequested: _onExitRequested,
    );
    // After the first frame, so a crash before it cannot leave a prevented
    // close that nothing answers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      unawaited(
        ref
            .read(windowCloseGuardProvider)
            .install(() => _flusher.flushForExit(container))
            .catchError((Object error, StackTrace stack) {
              _log.warning('window close guard failed', error, stack);
            }),
      );
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _flusher.dispose();
    super.dispose();
  }

  void _onState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      final container = ProviderScope.containerOf(context, listen: false);
      unawaited(
        _flusher.flush(container).catchError((Object error, StackTrace stack) {
          _log.warning('flush on pause failed', error, stack);
        }),
      );
    }
  }

  Future<AppExitResponse> _onExitRequested() async {
    final container = ProviderScope.containerOf(context, listen: false);
    await _flusher.flushForExit(container);
    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(extensionRegistryProvider);
    final themes = ref.watch(appThemeProvider);
    return MaterialApp.router(
      title: 'Kanaru',
      theme: themes.light,
      darkTheme: themes.dark,
      // A cover change re-themes at once; tweening the whole app's colours
      // on every skip is costly and not wanted.
      themeAnimationDuration: Duration.zero,
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
