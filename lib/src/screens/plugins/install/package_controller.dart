import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../foundation/result.dart';
import '../../../plugins/domain/install/held_package.dart';
import '../../../plugins/domain/install/install_result.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../../../plugins/state/install_ops.dart';
import '../problems/install_problem.dart';
import 'package_exit.dart';
import 'package_models.dart';

export 'package_models.dart';

final _log = Logger('plugin_install');

/// State of the install / update screen: prepares the package (download or
/// read, check, hold), installs the one the user reviewed, and holds nothing
/// past its end (the held token is discarded in [dispose], on every exit).
/// Nothing is written before [confirm].
class PackageController extends ChangeNotifier {
  PackageController({
    required this.ops,
    required this.start,
    required this.subject,
    this.onInstalledAfterClose,
  });

  final InstallOps ops;

  /// Starts a preparation; called again by [prepare] after an error or a
  /// stale review.
  final PrepareOperation Function() start;
  final PackageSubject subject;

  /// Called when the plugin was written after the screen had already gone
  /// (the install was in flight): the user still hears that it happened.
  final void Function(PackageInstalled installed)? onInstalledAfterClose;

  PackagePhase phase = PackagePhase.loading;
  HeldPackage? held;
  PrepareProgress? progress;

  /// Set with [PackagePhase.failed]: one of the two.
  PrepareFailure? prepareFailure;
  InstallFailure? writeFailure;
  PackageNotice? notice;

  /// Free rule: a second streaming plugin from a file or link.
  bool proBlocked = false;

  /// Set once: the screen pops with it.
  PackageExit? exit;

  PrepareOperation? _op;
  StreamSubscription<PrepareProgress>? _sub;
  var _disposed = false;

  bool get isUpdate => held?.review is UpdateReview;

  /// Prepares the package. [notice] says why it runs again.
  Future<void> prepare({PackageNotice? notice}) async {
    _release();
    phase = PackagePhase.loading;
    held = null;
    progress = null;
    prepareFailure = null;
    writeFailure = null;
    proBlocked = false;
    this.notice = notice;
    _changed();
    final op = start();
    _op = op;
    _sub = op.progress.listen((p) {
      progress = p;
      _changed();
    });
    final result = await op.result;
    if (_disposed || !identical(op, _op)) {
      if (result case Ok(:final value)) ops.discard(value.token);
      return;
    }
    switch (result) {
      case Err(:final error):
        _prepareFailed(error);
      case Ok(:final value):
        await _prepared(value);
    }
  }

  void _prepareFailed(PrepareFailure failure) {
    final problem = problemOfPrepareFailure(
      failure,
      subject: subject.name,
      isFile: subject.isFile,
    );
    if (problem != null) {
      exit = PackageRefused(problem);
    } else {
      prepareFailure = failure;
      phase = PackagePhase.failed;
    }
    _changed();
  }

  Future<void> _prepared(HeldPackage package) async {
    final problem = problemOfHeld(package);
    if (problem != null) {
      ops.discard(package.token);
      exit = PackageRefused(problem);
      _changed();
      return;
    }
    // Held before the next await, so a close in between still discards it.
    held = package;
    final bool blocked;
    try {
      blocked = await ops.streamingBlocked(package);
    } on Object catch (error) {
      _log.warning('Checking the streaming rule failed: ${error.runtimeType}');
      if (_disposed || !identical(held, package)) return;
      ops.discard(package.token);
      held = null;
      writeFailure = InstallFailure.unexpected;
      phase = PackagePhase.failed;
      _changed();
      return;
    }
    if (_disposed || !identical(held, package)) return;
    proBlocked = blocked;
    phase = PackagePhase.ready;
    _changed();
  }

  /// Installs or updates the reviewed package.
  Future<void> confirm() async {
    final package = held;
    if (package == null || phase != PackagePhase.ready || proBlocked) return;
    phase = PackagePhase.working;
    _changed();
    final InstallResult result;
    try {
      result = await ops.install(package.token);
    } on Object catch (error) {
      _log.warning('Installing failed: ${error.runtimeType}');
      if (_disposed) return;
      writeFailure = InstallFailure.unexpected;
      phase = PackagePhase.failed;
      _changed();
      return;
    }
    if (result case Installed(:final installId)) {
      final installed = PackageInstalled(
        installId: installId,
        name: package.package.manifest.name,
        version: package.package.manifest.version,
        updated: package.review is UpdateReview,
      );
      if (_disposed) {
        onInstalledAfterClose?.call(installed);
        return;
      }
      exit = installed;
      _changed();
      return;
    }
    if (_disposed) return;
    switch (result) {
      case Installed():
        break; // handled above

      case InstallRefused(:final failure):
        await _refused(package, failure);
      case InstallPrepareFailed(:final failure):
        prepareFailure = failure;
        phase = PackagePhase.failed;
        _changed();
      case InstallNeedsReview(:final held):
        // Only silent paths return this; keep nothing and ask to look again.
        ops.discard(held.token);
        writeFailure = InstallFailure.unexpected;
        phase = PackagePhase.failed;
        _changed();
    }
  }

  Future<void> _refused(HeldPackage package, InstallFailure failure) async {
    switch (failure) {
      case InstallFailure.reviewStale:
        return prepare(notice: PackageNotice.stale);
      case InstallFailure.tokenExpired:
        return prepare(notice: PackageNotice.expired);
      case InstallFailure.proRequired:
        // The token is spent; [Cài] stays locked.
        proBlocked = true;
        phase = PackagePhase.ready;
      default:
        final source = package.source;
        final problem = problemOfFailure(
          failure,
          subject: source is FileHeldSource
              ? source.fileName
              : package.package.manifest.name,
          isFile: source is FileHeldSource,
          existing: package.snapshot?.source,
        );
        if (problem != null) {
          exit = PackageRefused(problem);
        } else {
          writeFailure = failure;
          phase = PackagePhase.failed;
        }
    }
    _changed();
  }

  void _release() {
    _sub?.cancel();
    _sub = null;
    _op?.cancel();
    _op = null;
    final token = held?.token;
    if (token != null) ops.discard(token);
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _release();
    super.dispose();
  }
}
