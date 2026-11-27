import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_providers.dart';
import '../../platform/state/window_close_provider.dart';
import '../../screens/settings/state/appearance_settings.dart';
import '../../screens/settings/state/display_settings.dart';
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

class _KanaruAppState extends ConsumerState<KanaruApp>
    with WidgetsBindingObserver {
  late final AppLifecycleListener _lifecycle;
  final _flusher = FlushCoordinator();
  late Brightness _platformBrightness;

  @override
  void initState() {
    super.initState();
    _platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    _flusher.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final next = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (next != _platformBrightness) setState(() => _platformBrightness = next);
  }

  void _onState(AppLifecycleState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final Future<void> work;
    switch (lifecycleFlush(
      state,
      android: defaultTargetPlatform == TargetPlatform.android,
    )) {
      case LifecycleFlush.none:
        return;
      case LifecycleFlush.live:
        work = flushLive(container);
      case LifecycleFlush.all:
        work = _flusher.flush(container);
    }
    unawaited(
      work.catchError((Object error, StackTrace stack) {
        _log.warning('flush on pause failed', error, stack);
      }),
    );
  }

  Future<AppExitResponse> _onExitRequested() async {
    final container = ProviderScope.containerOf(context, listen: false);
    await _flusher.flushForExit(container);
    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(extensionRegistryProvider);
    final mode = ref.watch(themeChoiceProvider).mode;
    // The brightness in use is resolved here (setting, else the platform) so
    // only that theme is built. The same data goes to both slots, and
    // `themeMode` names the matching one.
    final brightness = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => _platformBrightness,
    };
    final theme = ref.watch(appThemeProvider(brightness));
    final textFactor = ref.watch(appTextScaleProvider) / 100;
    final motion = ref.watch(appMotionProvider);
    return MaterialApp.router(
      title: 'Kanaru',
      theme: theme,
      darkTheme: theme,
      // A cover change re-themes at once; tweening the whole app's colours
      // on every skip is costly and not wanted.
      themeAnimationDuration: Duration.zero,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: Locale(ref.watch(appLanguageProvider).name),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...registry.l10nDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      // Always wraps a MediaQuery (even at 100 % with motion on), so a toggle
      // changes values and never the widget structure above the router.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: _CappedTextScaler(media.textScaler, textFactor),
            disableAnimations: media.disableAnimations || !motion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// The system text scaler times [factor], never above [maxScale] overall.
class _CappedTextScaler extends TextScaler {
  const _CappedTextScaler(this.system, this.factor);

  static const double maxScale = 2.0;

  final TextScaler system;
  final double factor;

  @override
  double scale(double fontSize) {
    final scaled = system.scale(fontSize) * factor;
    final cap = fontSize * maxScale;
    return scaled > cap ? cap : scaled;
  }

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _CappedTextScaler &&
      other.factor == factor &&
      other.system == system;

  @override
  int get hashCode => Object.hash(system, factor);
}
