import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/track_translation_notifier.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_commands.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_tune_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_settings_link.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_links.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_modal.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart'
    show ConfigWrite;
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart'
    show pluginIconProvider;
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/memory_settings_store.dart';
import '../../lyrics_ui_host.dart' show syncedLyrics;

const trackOne = TrackId(1);

/// A value a test sets and the overridden providers follow.
class Box<T> extends Notifier<T> {
  Box(this.initial);
  final T initial;

  @override
  T build() => initial;

  void set(T value) => state = value;
}

NotifierProvider<Box<T>, T> box<T>(T initial) =>
    NotifierProvider<Box<T>, T>(() => Box(initial));

/// A translation that shows what the test put in the view box.
class _FakeTranslation extends TrackTranslation {
  _FakeTranslation(super.trackId, this.source);

  final NotifierProvider<Box<TranslationView>, TranslationView> source;

  @override
  TranslationView build() => ref.watch(source);
}

/// Records every command; settings commands stay real over memory settings.
class FakeCommands extends TranslationCommands {
  FakeCommands(super.ref, this.host);

  final TranslateHost host;

  @override
  void retranslate(TrackId id) => host.calls.add('retranslate');

  @override
  void retry(TrackId id) => host.calls.add('retry');

  @override
  void cancelRetranslate(TrackId id) => host.calls.add('cancel');

  @override
  Future<bool> setTarget(TrackId id, String? lang) async {
    host.calls.add('target:$lang');
    if (host.targetOk) host.container.read(host.target.notifier).set(lang!);
    return host.targetOk;
  }

  @override
  Future<ConfigWrite> setModel(String installId, String? value) async {
    host.calls.add('model:$value');
    return host.write;
  }

  @override
  Future<ConfigWrite> setStyle(String installId, String? value) async {
    host.calls.add('style:$value');
    return host.write;
  }

  @override
  Future<ConfigWrite> setNote(String installId, String? value) async {
    host.calls.add('note:$value');
    return host.write;
  }
}

/// The select fields of a test AI plugin.
SelectField modelField({int count = 3}) => SelectField(
  key: 'model',
  title: 'Model',
  defaultValue: 'm0',
  custom: true,
  options: [
    for (var i = 0; i < count; i++)
      ConfigOption(value: 'm$i', title: 'Model $i', subtitle: 'About $i'),
  ],
);

SelectField styleField() => const SelectField(
  key: 'style',
  title: 'Style',
  defaultValue: 'natural',
  options: [
    ConfigOption(value: 'natural', title: 'Natural'),
    ConfigOption(value: 'poetic', title: 'Poetic'),
  ],
);

const google = TranslateService(
  installId: 'google',
  name: 'Google Translate',
  ai: false,
);
const gemini = TranslateService(
  installId: 'gemini',
  name: 'Gemini Translate',
  ai: true,
);

TranslateTune tuneOf({
  SelectField? model,
  String modelValue = 'm0',
  String styleValue = 'natural',
  String note = '',
}) => TranslateTune(
  installId: 'gemini',
  pluginName: 'Gemini Translate',
  pluginVersion: 1,
  model: model ?? modelField(),
  style: styleField(),
  modelValue: modelValue,
  styleValue: styleValue,
  note: note,
  hasNote: true,
);

/// The providers the "Dịch lời" modal reads, driven by the test, over memory
/// settings and a router with the pages the modal can lead to.
class TranslateHost {
  TranslateHost({
    TranslateServices? services,
    TranslateTune? tune,
    int lines = 3,
  }) {
    view = box<TranslationView>(TranslationView.idle);
    this.services = box<TranslateServices>(
      services ??
          const TranslateServices(all: [google, gemini], current: google),
    );
    this.tune = box<TranslateTune?>(tune);
    credit = box<TranslationCredit?>(null);
    target = box<String>('vi');
    playing = box<TrackId?>(trackOne);
    container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        trackTranslationProvider.overrideWith2(
          (id) => _FakeTranslation(id, view),
        ),
        effectiveTranslationTargetProvider.overrideWith(
          (ref, id) => ref.watch(target),
        ),
        translationCreditProvider.overrideWith((ref, id) => ref.watch(credit)),
        translateServicesProvider.overrideWith(
          (ref) => AsyncData(ref.watch(this.services)),
        ),
        translateTuneProvider.overrideWith(
          (ref, id) => AsyncData(ref.watch(this.tune)),
        ),
        translationCommandsProvider.overrideWith(
          (ref) => FakeCommands(ref, this),
        ),
        trackLyricsProvider.overrideWith(
          (ref, id) => LyricsShown(syncedLyrics(lines)),
        ),
        playingLyricsProvider.overrideWith(
          (ref) => PlayingLyrics(
            entryId: 1,
            trackId: ref.watch(playing),
            lyrics: const LyricsNone(),
          ),
        ),
        playingLyricsLineProvider.overrideWith((ref) => 1),
        pluginIconProvider.overrideWith((ref, id) async => null),
      ],
    );
    addTearDown(container.dispose);
  }

  late final NotifierProvider<Box<TranslationView>, TranslationView> view;
  late final NotifierProvider<Box<TranslateServices>, TranslateServices>
  services;
  late final NotifierProvider<Box<TranslateTune?>, TranslateTune?> tune;
  late final NotifierProvider<Box<TranslationCredit?>, TranslationCredit?>
  credit;
  late final NotifierProvider<Box<String>, String> target;
  late final NotifierProvider<Box<TrackId?>, TrackId?> playing;
  late final ProviderContainer container;
  late final GoRouter router;

  /// What the fake commands were asked, in order.
  final calls = <String>[];
  bool targetOk = true;
  ConfigWrite write = ConfigWrite.written;

  void setView(TranslationView v) => container.read(view.notifier).set(v);
  void setServices(TranslateServices s) =>
      container.read(services.notifier).set(s);
  void setTune(TranslateTune? t) => container.read(tune.notifier).set(t);
  void setCredit(TranslationCredit? c) =>
      container.read(credit.notifier).set(c);
  void play(TrackId? id) => container.read(playing.notifier).set(id);

  Future<void> turnOn([bool on = true]) =>
      container.read(translationOnProvider.notifier).set(on);

  /// Where the router is, with its query.
  String get location =>
      router.routerDelegate.currentConfiguration.uri.toString();

  /// Pumps an app with a button that opens the modal for track 1, opens it.
  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    bool followsPlaying = false,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showTranslateModal(
                  context,
                  trackOne,
                  followsPlaying: followsPlaying,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        for (final path in [
          lyricsSettingsLocation,
          '/settings/plugins',
          '/settings/plugins/p/gemini',
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('page $path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: app!,
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  /// Lets a route finish; a running spinner never lets `pumpAndSettle` end.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Presses Esc.
  Future<void> esc(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
  }
}

/// The semantics of the row (or control) with [title]: finds the nearest
/// selection row or segment.
bool isSelectedRow(WidgetTester tester, String title) {
  final row = find.ancestor(
    of: find.text(title),
    matching: find.byType(SelectionRow),
  );
  return isSemantics(isSelected: true).matches(tester.getSemantics(row), {});
}

String get translatePluginStore => translatePluginStoreLocation;
