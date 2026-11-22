import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/install/update_diff.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../plugins/data/store_test_support.dart';
import '../../../plugins/domain/plugin_test_support.dart';
import 'plugin_fixtures.dart';

typedef Prepared = Result<HeldPackage, PrepareFailure>;

/// A held package read from a real zip of [manifest], with the review and
/// source a test needs.
HeldPackage heldOf({
  Map<String, Object?>? manifest,
  Map<String, Object> extra = const {},
  PackageReview review = const InstallReview(),
  HeldSource source = const RepoHeldSource(
    repoId: 1,
    repoUrl: 'https://repo1.example.com/plugins.json',
    slug: 'demo',
  ),
  String token = 'token-1',
}) => HeldPackage(
  token: token,
  package: packageOf(manifest, extra),
  installId: 'id-demo',
  source: source,
  review: review,
  snapshot: null,
);

UpdateReview updateReview({
  List<String> newHosts = const [],
  VersionOrder order = VersionOrder.newer,
  KindChange kind = KindChange.none,
}) => UpdateReview(
  UpdateDiff(newHosts: newHosts, versionOrder: order, kindChange: kind),
);

/// Records what the screens ask of the install services and answers from
/// fields a test sets.
class FakeInstallOps implements InstallOps {
  /// Answers every prepare call; replace per test.
  Future<Prepared> Function() onPrepare = () async => Ok(heldOf());
  final prepared = <String>[];
  final discarded = <String>[];
  final installed = <String>[];
  final removed = <String>[];
  var updateCalls = <String>[];
  var updateAllCalls = 0;
  var blocked = false;
  Future<InstallResult> Function(String token) onInstall = (token) async =>
      const Installed('id-demo', InstallOutcome.installed);
  Future<UpdateRun> Function(String id) onUpdate = (_) async =>
      const UpdateRun(Installed('id-demo', InstallOutcome.updated), version: 4);
  Future<UpdateAllState> Function() onUpdateAll = () async =>
      const UpdateAllState();
  RemovePreview? preview = const RemovePreview(
    installId: 'id-demo',
    name: 'Demo',
    author: 'someone',
    version: 3,
    kind: null,
  );
  RemoveResult removeResult = RemoveResult.removed;

  PrepareOperation _op(String what) {
    prepared.add(what);
    return PrepareOperation(CancelToken(), const Stream.empty(), onPrepare());
  }

  @override
  PrepareOperation prepareInstall(String installId) => _op('repo:$installId');
  @override
  PrepareOperation prepareUpdate(String installId) => _op('update:$installId');
  @override
  PrepareOperation prepareFile(PickedDocument doc) => _op('file:${doc.name}');
  @override
  PrepareOperation prepareLink(String link) => _op('link:$link');
  @override
  PrepareOperation prepareAfterRefresh(HeldPackage held) =>
      _op('refresh:${held.token}');
  @override
  void discard(String token) => discarded.add(token);
  @override
  Future<bool> streamingBlocked(HeldPackage held) async => blocked;
  @override
  Future<InstallResult> install(String token) {
    installed.add(token);
    return onInstall(token);
  }

  @override
  Future<UpdateRun> update(String installId) {
    updateCalls.add(installId);
    return onUpdate(installId);
  }

  @override
  Future<UpdateAllState> updateAll() {
    updateAllCalls++;
    return onUpdateAll();
  }

  @override
  Future<RemovePreview?> removePreview(String installId) async => preview;
  @override
  Future<RemoveResult> remove(String installId) async {
    removed.add(installId);
    return removeResult;
  }
}

/// A picker that returns [doc] (or throws) and reads nothing.
class FakeZipPicker implements DocumentPicker {
  FakeZipPicker(this.doc, {this.fails = false});

  final PickedDocument? doc;
  final bool fails;

  @override
  Future<PickedDocument?> openDocument(DocumentFilter filter) async {
    if (fails) {
      throw const DocumentPickerException(DocumentPickerFailure.failed);
    }
    return doc;
  }

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) async => null;
  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) async => const Err(DocumentError.unreadable);
  @override
  Future<Result<void, DocumentError>> write(
    SaveTarget target,
    Uint8List bytes,
  ) async => const Err(DocumentError.unwritable);
  @override
  Future<void> discard(SaveTarget target) async {}
}

const narrowWindow = Size(400, 900);
const wideWindow = Size(1400, 1000);

/// A page with one button, [label], that runs [onTap] with its context, over
/// the install fakes. Snack bars land on its Scaffold.
Future<void> pumpFlowHost(
  WidgetTester tester, {
  required FakeInstallOps ops,
  required void Function(BuildContext context) onTap,
  Size size = narrowWindow,
  List<Override> overrides = const [],
  String label = 'go',

  /// False while something spins on purpose (a package that is still loading).
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        installOpsProvider.overrideWithValue(ops),
        repoViewsProvider.overrideWithValue(
          const AsyncData([
            RepoView(
              id: 1,
              name: 'Kanaru Plugins',
              url: 'https://repo1.example.com/plugins.json',
              pluginCount: 3,
            ),
          ]),
        ),
        storeOpsProvider.overrideWithValue(FakeStoreOps()),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => onTap(context),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text(label));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// A lyrics manifest whose `plugin.json` has [change] applied to its
/// `metadata`.
Map<String, Object?> lyricsManifest({
  int version = 3,
  List<String> hosts = const ['music.example.com'],
  String author = 'someone',
}) => withMeta((m) {
  m['version'] = version;
  m['hosts'] = hosts;
  m['author'] = author;
});
