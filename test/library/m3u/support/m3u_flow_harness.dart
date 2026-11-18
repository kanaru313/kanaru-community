import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/data/m3u/m3u_export_service.dart';
import 'package:kanaru/src/library/data/m3u/m3u_import_service.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/data/m3u/m3u_scan_rules.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/library/state/m3u/m3u_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:material_ui/material_ui.dart';

import 'package:kanaru/src/library/ui/m3u/m3u_import_progress_card.dart';

import 'm3u_env.dart';
import 'm3u_fixtures.dart';

/// The picker the flows see: dialogs are scripted ([onOpen], [onCreate]),
/// reads / writes / discards go to the env's [FakePicker] (so tests assert on
/// `env.picker`). A write also lands in the target's file when it has a
/// local path, like the Linux picker.
class FlowPicker implements DocumentPicker {
  FlowPicker(this.inner);

  final FakePicker inner;

  Future<PickedDocument?> Function() onOpen = () async => null;
  Future<SaveTarget?> Function(String suggestedName) onCreate = (_) async =>
      null;

  /// While set, `read` waits for it: a slow file.
  Completer<void>? readGate;

  int opens = 0;
  DocumentFilter? openFilter, createFilter;
  String? suggestedName;

  @override
  Future<PickedDocument?> openDocument(DocumentFilter filter) {
    opens++;
    openFilter = filter;
    return onOpen();
  }

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) {
    this.suggestedName = suggestedName;
    createFilter = filter;
    return onCreate(suggestedName);
  }

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) async {
    await readGate?.future;
    return inner.read(doc, maxBytes: maxBytes);
  }

  @override
  Future<Result<void, DocumentError>> write(
    SaveTarget target,
    Uint8List bytes,
  ) async {
    final result = await inner.write(target, bytes);
    final path = target.localPath;
    if (result is Ok && path != null) File(path).writeAsBytesSync(bytes);
    return result;
  }

  @override
  Future<void> discard(SaveTarget target) => inner.discard(target);
}

/// A service whose `importDocument` fails with [error] (the isolate or the
/// parser failing).
class ThrowingImportService extends M3uImportService {
  ThrowingImportService(M3uEnv env, FlowPicker picker, this.error)
    : super(
        env.db,
        env.repo,
        picker,
        realPath,
        env.scans,
        const ShortTrackRule.off(),
        androidStorage: false,
      );

  final Object error;

  @override
  Future<Result<M3uImportResult, M3uImportError>> importDocument(
    PickedDocument doc, {
    required String fallbackName,
    void Function(M3uImportProgress p)? onProgress,
  }) async => throw error;
}

/// An app with a host page at `/` and a stub `/playlists/:uid`, over a
/// [M3uEnv] (real in-memory database, temp folders), with the flows' services
/// and picker wired to it.
class M3uFlowHarness {
  M3uFlowHarness._(
    this.env,
    this.picker,
    this.container,
    this.router,
    this._hostKey,
  );

  final M3uEnv env;
  final FlowPicker picker;
  final ProviderContainer container;
  final GoRouter router;
  final GlobalKey _hostKey;

  static Future<M3uFlowHarness> pump(
    WidgetTester tester, {
    double width = 400,
    double textScale = 1,
    PlaylistStore Function(M3uEnv env)? store,
    M3uImportService Function(M3uEnv env, FlowPicker picker)? importService,
    List<Override> overrides = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.reset);
    final env = (await tester.runAsync(M3uEnv.open))!;
    final picker = FlowPicker(env.picker);
    final playlistStore = store?.call(env) ?? env.repo;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(env.db),
        playlistStoreProvider.overrideWithValue(playlistStore),
        documentPickerProvider.overrideWithValue(picker),
        m3uImportServiceProvider.overrideWithValue(
          importService?.call(env, picker) ??
              M3uImportService(
                env.db,
                playlistStore,
                picker,
                realPath,
                env.scans,
                const ShortTrackRule.off(),
                androidStorage: false,
              ),
        ),
        m3uExportServiceProvider.overrideWithValue(
          M3uExportService(env.db, picker, realPath),
        ),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    final key = GlobalKey();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Column(
              children: [
                const M3uImportProgressCard(),
                SizedBox(key: key),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/playlists/:uid',
          builder: (_, state) =>
              Scaffold(body: Text('PAGE ${state.pathParameters['uid']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
    return M3uFlowHarness._(env, picker, container, router, key);
  }

  BuildContext hostContext(WidgetTester tester) =>
      tester.element(find.byKey(_hostKey, skipOffstage: false));

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(hostContext(tester));

  /// The location the router is at now.
  String location() =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  /// Runs [flow] with the host context; [FlowRun.done] turns true when it ends.
  FlowRun start(WidgetTester tester, Future<void> Function(BuildContext) flow) {
    final f = FlowRun();
    unawaited(flow(hostContext(tester)).whenComplete(() => f.done = true));
    return f;
  }

  /// Waits (real time, bounded) until [condition] holds, pumping between
  /// polls: the flows do real database and file work.
  Future<void> until(
    WidgetTester tester,
    bool Function() condition, {
    String? what,
  }) async {
    final end = DateTime.now().add(const Duration(seconds: 10));
    while (!condition()) {
      if (DateTime.now().isAfter(end)) {
        fail('timed out waiting for ${what ?? 'condition'}');
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> untilDone(WidgetTester tester, FlowRun flow) =>
      until(tester, () => flow.done, what: 'the flow to finish');

  Future<void> untilFound(WidgetTester tester, Finder finder) => until(
    tester,
    () => finder.evaluate().isNotEmpty,
    what: 'a widget to appear',
  );
}

/// Completion flag of a started flow.
class FlowRun {
  bool done = false;
}
