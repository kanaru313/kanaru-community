import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/plugins/data/install/held_packages.dart';
import 'package:kanaru/src/plugins/data/install/held_token_store.dart';
import 'package:kanaru/src/plugins/data/install/held_source_mapping.dart';
import 'package:kanaru/src/plugins/data/install/package_sources.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_cache.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_codec.dart';
import 'package:kanaru/src/plugins/data/repos/repo_address_guard.dart';
import 'package:kanaru/src/plugins/data/store/plugin_repo_rows.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/install/script_checker.dart';
import 'package:kanaru/src/plugins/domain/install/update_diff.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/plugins/domain/net/net_policy.dart';

import '../../database/support/test_db.dart';
import '../domain/plugin_test_support.dart';
import '../fixtures/catalog_support.dart';
import '../fixtures/zip_builders.dart';
import 'services_test_support.dart';
import 'store_test_support.dart';

const _zipUrl = 'https://cdn.example.com/netease/plugin.zip';

void main() {
  late AppDatabase db;
  late PluginRows rows;
  late PluginRepoRows repoRows;
  late CatalogCache catalogs;
  late FakeFetcher fetcher;
  late FakeChecker checker;
  late FakePicker picker;
  late HeldPackages held;
  late HeldTokenStore tokens;
  var now = DateTime(2026);
  var resolved = [publicIp()];
  Uint8List zip = validZip();
  Future<Object?> Function(int)? refreshHook;

  HeldPackages build({Duration scriptTimeout = const Duration(seconds: 10)}) =>
      HeldPackages(
        sources: PackageSources(
          fetcher: fetcher,
          guard: RepoAddressGuard(
            resolver: (_) async => resolved,
            clock: () => now,
          ),
          picker: picker,
          fileTimeout: const Duration(milliseconds: 80),
        ),
        checker: checker,
        rows: rows,
        repoRows: repoRows,
        catalogs: catalogs,
        tokens: tokens,
        scriptTimeout: scriptTimeout,
        refreshRepo: (id) => refreshHook!(id),
      );

  /// Stores a repository whose catalog lists `netease` with [over].
  Future<int> addRepo({
    Map<String, Object?> over = const {},
    AddressKind kind = AddressKind.public,
  }) async {
    final catalog = okCatalog(
      catalogJson([
        entryJson({
          'hosts': ['music.example.com'],
          'path': _zipUrl,
          ...over,
        }),
      ]),
    );
    final (_, id) = await repoRows.add(
      url: catalogUrl.toString(),
      name: 'Kho',
      catalogJson: encodeCatalog(catalog),
      addressKind: kind,
      now: 1,
    );
    return id!;
  }

  Future<HeldPackage> ok(PrepareOperation op) async =>
      switch (await op.result) {
        Ok(:final value) => value,
        Err(:final error) => fail('refused: $error'),
      };

  Future<PrepareFailure> refused(PrepareOperation op) async =>
      switch (await op.result) {
        Ok() => fail('accepted'),
        Err(:final error) => error,
      };

  List<HeldProblem> problemsOf(HeldPackage p) =>
      (p.review as ProblemsReview).problems;

  setUp(() {
    db = openTestDb();
    rows = PluginRows(db);
    repoRows = PluginRepoRows(db);
    catalogs = CatalogCache();
    now = DateTime(2026);
    resolved = [publicIp()];
    zip = validZip();
    fetcher = FakeFetcher((_) async => served(zip));
    checker = FakeChecker();
    picker = FakePicker((doc, max) async => Ok(zip));
    tokens = HeldTokenStore(clock: () => now);
    refreshHook = null;
    held = build();
  });
  tearDown(() => db.close());

  group('from a file', () {
    test('a new plugin is an install review and writes nothing', () async {
      final result = await ok(held.prepareFromFile(pickedZip('demo.zip')));
      expect(result.review, isA<InstallReview>());
      expect(result.snapshot, isNull);
      expect(result.source, isA<FileHeldSource>());
      expect(result.installId, fileInstallId('Demo', 'someone'));
      expect(result.sha256, result.package.sha256);
      expect(await rows.live(), isEmpty);
    });

    test('asks the picker for at most 5 MiB + 1 and refuses more', () async {
      var asked = 0;
      picker.reader = (doc, max) async {
        asked = max;
        return Ok(Uint8List(5 * 1024 * 1024 + 1));
      };
      final failure = await refused(held.prepareFromFile(pickedZip()));
      expect(asked, 5 * 1024 * 1024 + 1);
      expect(failure, isA<FileUnreadable>());
      expect((failure as FileUnreadable).error, DocumentError.tooLarge);
    });

    test('a picker error is a typed failure', () async {
      picker.reader = (_, _) async => const Err(DocumentError.unreadable);
      final failure = await refused(held.prepareFromFile(pickedZip()));
      expect((failure as FileUnreadable).error, DocumentError.unreadable);
    });

    test('a picker that throws is a typed failure', () async {
      picker.reader = (_, _) async => throw StateError('provider');
      final failure = await refused(held.prepareFromFile(pickedZip()));
      expect((failure as FileUnreadable).error, DocumentError.unreadable);
    });

    test('a name that is not .zip is refused before reading', () async {
      var read = false;
      picker.reader = (_, _) async {
        read = true;
        return Ok(zip);
      };
      final failure = await refused(held.prepareFromFile(pickedZip('a.txt')));
      expect((failure as FileUnreadable).error, DocumentError.notAFile);
      expect(read, isFalse);
    });

    test('a slow provider times out and its late answer is dropped', () async {
      final late = Completer<Result<Uint8List, DocumentError>>();
      picker.reader = (_, _) => late.future;
      final failure = await refused(held.prepareFromFile(pickedZip()));
      expect(failure, isA<FileTimedOut>());
      late.complete(Ok(zip));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(tokens.length, 0);
    });

    test('a late failure of the provider does not escape', () async {
      final late = Completer<Result<Uint8List, DocumentError>>();
      picker.reader = (_, _) => late.future;
      await refused(held.prepareFromFile(pickedZip()));
      late.completeError(StateError('late'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('bytes that are not a plugin zip are PackageUnreadable', () async {
      zip = Uint8List.fromList([1, 2, 3, 4]);
      final failure = await refused(held.prepareFromFile(pickedZip()));
      expect(failure, isA<PackageUnreadable>());
    });
  });

  group('from a link', () {
    test(
      'fetches under the link policy and keeps the link as source',
      () async {
        final result = await ok(
          held.prepareFromLink(' http://192.168.1.5:8000/demo.zip '),
        );
        expect(fetcher.calls.single.policy, NetPolicy.link);
        expect(fetcher.calls.single.uri.host, '192.168.1.5');
        expect(
          (result.source as LinkHeldSource).url,
          'http://192.168.1.5:8000/demo.zip',
        );
        expect(result.installId, fileInstallId('Demo', 'someone'));
      },
    );

    test('an address that is not a URL is invalidUrl', () async {
      final failure = await refused(held.prepareFromLink('http://['));
      expect(
        (failure as DownloadFailed).failure.kind,
        FetchFailureKind.invalidUrl,
      );
      expect(fetcher.calls, isEmpty);
    });

    test('a download failure is typed', () async {
      fetcher.answer = (_) async => failed(
        FetchFailureKind.blockedAddress,
        reason: AddressProblem.refusedAddress,
      );
      final failure = await refused(
        held.prepareFromLink('https://x.example.com/a.zip'),
      );
      expect(
        (failure as DownloadFailed).failure.reason,
        AddressProblem.refusedAddress,
      );
    });
  });

  group('from a repository', () {
    test('uses the entry, the package policy and the catalog class', () async {
      final id = await addRepo();
      final result = await ok(held.prepareFromRepo(id, 'netease'));
      expect(result.review, isA<InstallReview>());
      final call = fetcher.calls.single;
      expect(call.uri.toString(), _zipUrl);
      expect(call.policy, NetPolicy.package);
      expect(call.catalogKind, AddressKind.public);
      expect(result.installId, repoInstallId(catalogUrl.toString(), 'netease'));
      final source = result.source as RepoHeldSource;
      expect([source.repoId, source.slug], [id, 'netease']);
    });

    test(
      'a stored local class narrows to public when the address is public',
      () async {
        final id = await addRepo(kind: AddressKind.local);
        await ok(held.prepareFromRepo(id, 'netease'));
        expect(fetcher.calls.single.catalogKind, AddressKind.public);
      },
    );

    test(
      'a repository address that is refused now refuses the download',
      () async {
        final id = await addRepo();
        resolved = [InternetAddress('0.0.0.0')];
        final failure = await refused(held.prepareFromRepo(id, 'netease'));
        expect(
          (failure as DownloadFailed).failure.kind,
          FetchFailureKind.blockedAddress,
        );
        expect(fetcher.calls, isEmpty);
      },
    );

    test('a lookup that fails refuses the download (no fallback)', () async {
      final id = await addRepo();
      final broken = HeldPackages(
        sources: PackageSources(
          fetcher: fetcher,
          guard: RepoAddressGuard(
            resolver: (_) async => throw StateError('dns'),
          ),
          picker: picker,
        ),
        checker: checker,
        rows: rows,
        repoRows: repoRows,
        catalogs: catalogs,
      );
      final failure = await refused(broken.prepareFromRepo(id, 'netease'));
      expect(
        (failure as DownloadFailed).failure.kind,
        FetchFailureKind.network,
      );
      expect(fetcher.calls, isEmpty);
    });

    test('a removed repository or entry is EntryGone', () async {
      expect(
        await refused(held.prepareFromRepo(99, 'netease')),
        isA<EntryGone>(),
      );
      final id = await addRepo();
      expect(
        await refused(held.prepareFromRepo(id, 'other')),
        isA<EntryGone>(),
      );
    });

    test('an entry of a newer app is refused before any download', () async {
      final id = await addRepo(over: {'apiVersion': 99});
      expect(
        await refused(held.prepareFromRepo(id, 'netease')),
        isA<EntryNeedsNewerApp>(),
      );
      expect(fetcher.calls, isEmpty);
    });

    test(
      'a package that differs from the entry carries the differences',
      () async {
        final id = await addRepo(over: {'version': 4});
        final result = await ok(held.prepareFromRepo(id, 'netease'));
        final diff = problemsOf(result).single as CatalogDiffers;
        expect(diff.differences, [CatalogMismatch.version]);
        expect(result.package.manifest.version, 3);
      },
    );

    test('sha256 and size of the entry are compared when given', () async {
      final id = await addRepo(
        over: {'sha256': 'a' * 64, 'size': zip.length + 1},
      );
      final result = await ok(held.prepareFromRepo(id, 'netease'));
      expect((problemsOf(result).single as CatalogDiffers).differences, [
        CatalogMismatch.sha256,
        CatalogMismatch.size,
      ]);
    });

    test(
      'refreshAndRetry re-reads the fresh entry and drops the old token',
      () async {
        final id = await addRepo(over: {'version': 4});
        final first = await ok(held.prepareFromRepo(id, 'netease'));
        expect(first.review, isA<ProblemsReview>());
        refreshHook = (repoId) async {
          final fresh = okCatalog(
            catalogJson([
              entryJson({
                'hosts': ['music.example.com'],
                'path': _zipUrl,
              }),
            ]),
          );
          await repoRows.saveCatalog(
            repoId,
            name: 'Kho',
            catalogJson: encodeCatalog(fresh),
            addressKind: AddressKind.public,
            now: 2,
          );
          return null;
        };
        final second = await ok(held.refreshAndRetry(first));
        expect(second.review, isA<InstallReview>());
        expect(held.peek(first.token), isNull);
        expect(held.peek(second.token), isNotNull);
      },
    );

    test('refreshAndRetry on a file package is refused', () async {
      final file = await ok(held.prepareFromFile(pickedZip()));
      expect(await refused(held.refreshAndRetry(file)), isA<EntryGone>());
    });
  });

  group('script check', () {
    test('every src script is checked, mapped or not', () async {
      zip = validZip(extra: {'src/common.js': 'var x = 1;'});
      await ok(held.prepareFromFile(pickedZip()));
      expect(checker.checked, ['common.js', 'lyrics.js', 'search.js']);
    });

    test(
      'a syntax error is a problem and the package stays inspectable',
      () async {
        checker.problems['lyrics.js'] = const ScriptProblem(
          line: 3,
          message: 'unexpected token',
        );
        final result = await ok(held.prepareFromFile(pickedZip()));
        final problem = problemsOf(result).single as ScriptSyntaxError;
        expect([problem.file, problem.problem.line], ['lyrics.js', 3]);
        expect(result.package.manifest.name, 'Demo');
      },
    );

    test('a checker that cannot run refuses the package', () async {
      checker.throwWith = StateError('library not loaded');
      expect(
        await refused(held.prepareFromFile(pickedZip())),
        isA<ScriptCheckUnavailable>(),
      );
      expect(tokens.length, 0);
    });

    test('a check that hangs is unavailable, not accepted', () async {
      checker.delay = const Duration(seconds: 1);
      held = build(scriptTimeout: const Duration(milliseconds: 30));
      expect(
        await refused(held.prepareFromFile(pickedZip())),
        isA<ScriptCheckUnavailable>(),
      );
    });
  });

  group('review against the installed plugin', () {
    final repoUrl = catalogUrl.toString();
    final id = repoInstallId(repoUrl, 'netease');

    Future<void> installFromRepo({int version = 3}) async {
      final package = packageOf(withMeta((m) => m['version'] = version));
      await rows.installOrRevive(
        id,
        draftOf(package),
        PluginSource.repo(repoUrl, 'netease'),
      );
    }

    test(
      'a newer version with a new host is an update that needs review',
      () async {
        await installFromRepo();
        zip = validZip(
          manifest: withMeta((m) {
            m['version'] = 4;
            m['hosts'] = ['music.example.com', 'api.other.example.com'];
          }),
        );
        final repo = await addRepo(
          over: {
            'version': 4,
            'hosts': ['music.example.com', 'api.other.example.com'],
          },
        );
        final result = await ok(held.prepareFromRepo(repo, 'netease'));
        final review = result.review as UpdateReview;
        expect(review.diff.needsReview, isTrue);
        expect(review.diff.newHosts, ['api.other.example.com']);
        expect(review.diff.versionOrder, VersionOrder.newer);
        expect(result.snapshot!.version, 3);
        expect(result.snapshot!.consentedHosts, ['music.example.com']);
        final source = result.snapshot!.source as RepoHeldSource;
        expect(source.slug, 'netease');
      },
    );

    test('the same zip as installed is a repair', () async {
      await installFromRepo();
      final repo = await addRepo();
      final result = await ok(held.prepareFromRepo(repo, 'netease'));
      expect(result.review, isA<RepairReview>());
    });

    test(
      'the same version with another zip is an update of order same',
      () async {
        await installFromRepo();
        zip = validZip(extra: {'src/extra.js': 'var y = 2;'});
        final repo = await addRepo();
        final review =
            (await ok(held.prepareFromRepo(repo, 'netease'))).review
                as UpdateReview;
        expect(review.diff.versionOrder, VersionOrder.same);
      },
    );

    test('an older version is an update of order older', () async {
      await installFromRepo(version: 5);
      final repo = await addRepo();
      final review =
          (await ok(held.prepareFromRepo(repo, 'netease'))).review
              as UpdateReview;
      expect(review.diff.versionOrder, VersionOrder.older);
    });

    test('a removed plugin counts as not installed', () async {
      await installFromRepo();
      await rows.remove(id);
      final repo = await addRepo();
      final result = await ok(held.prepareFromRepo(repo, 'netease'));
      expect(result.review, isA<InstallReview>());
      expect(result.snapshot, isNull);
    });

    test(
      'a file with the id of a repository row carries that row as snapshot',
      () async {
        // A file package takes its id from name + author, never a repo id; a
        // collision would show as a snapshot whose source is not a file.
        final fileId = fileInstallId('Demo', 'someone');
        await rows.installOrRevive(
          fileId,
          draftOf(packageOf()),
          const PluginSource.repo('https://repo.example.com/p.json', 'demo'),
        );
        final result = await ok(held.prepareFromFile(pickedZip()));
        expect(result.snapshot!.source, isA<RepoHeldSource>());
        expect(result.source, isA<FileHeldSource>());
      },
    );

    test(
      'the snapshot compares equal only while the row is unchanged',
      () async {
        await installFromRepo();
        final repo = await addRepo();
        final result = await ok(held.prepareFromRepo(repo, 'netease'));
        final now0 = snapshotNow(await rows.byId(id));
        expect(result.snapshot!.sameAs(now0), isTrue);
        await rows.switchPackage(
          id,
          draftOf(packageOf(withMeta((m) => m['version'] = 4)), 'v4-2000'),
        );
        expect(
          result.snapshot!.sameAs(snapshotNow(await rows.byId(id))),
          isFalse,
        );
      },
    );
  });

  group('tokens and progress', () {
    test('take releases the package once', () async {
      final result = await ok(held.prepareFromFile(pickedZip()));
      expect(held.take(result.token), same(result));
      expect(held.take(result.token), isNull);
    });

    test('discard drops it', () async {
      final result = await ok(held.prepareFromFile(pickedZip()));
      held.discard(result.token);
      expect(held.peek(result.token), isNull);
    });

    test('a token expires after 10 minutes', () async {
      final result = await ok(held.prepareFromFile(pickedZip()));
      now = now.add(const Duration(minutes: 9, seconds: 59));
      expect(held.peek(result.token), isNotNull);
      now = now.add(const Duration(seconds: 2));
      expect(held.peek(result.token), isNull);
    });

    test('at most two packages are held, the oldest goes', () async {
      final a = await ok(held.prepareFromFile(pickedZip('a.zip')));
      final b = await ok(held.prepareFromFile(pickedZip('b.zip')));
      final c = await ok(held.prepareFromFile(pickedZip('c.zip')));
      expect(held.peek(a.token), isNull);
      expect(held.peek(b.token), isNotNull);
      expect(held.peek(c.token), isNotNull);
      expect(a.token, isNot(b.token));
      expect(a.token.length, 32);
    });

    test('a problem package is held too (the screen shows it)', () async {
      checker.problems['search.js'] = const ScriptProblem(message: 'x');
      final result = await ok(held.prepareFromFile(pickedZip()));
      expect(held.peek(result.token), isNotNull);
    });

    test(
      'progress reports reading and the script checks, then closes',
      () async {
        final op = held.prepareFromFile(pickedZip());
        final events = <PrepareProgress>[];
        final done = op.progress.listen(events.add).asFuture<void>();
        await op.result;
        await done;
        expect(events.first.stage, PrepareStage.reading);
        final checks = events.where(
          (e) => e.stage == PrepareStage.checkingScripts,
        );
        expect(checks.map((e) => e.done), [0, 1]);
        expect(checks.first.total, 2);
      },
    );

    test('cancel stops a download with PrepareCancelled', () async {
      final gate = Completer<void>();
      fetcher.answer = (_) async {
        await gate.future;
        return served(zip);
      };
      final op = held.prepareFromLink('https://x.example.com/a.zip');
      await Future<void>.delayed(Duration.zero);
      op.cancel();
      expect(await refused(op), isA<PrepareCancelled>());
      gate.complete();
      expect(tokens.length, 0);
    });
  });
}

InstallSnapshot? snapshotNow(PluginRow? row) => row == null
    ? null
    : InstallSnapshot(
        installId: row.installId,
        version: row.version,
        consentedHosts: row.consentedHosts,
        packageSha256: row.packageSha256,
        source: heldSourceOf(row.source),
      );
