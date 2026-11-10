import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:path/path.dart' as p;

import '../../media/domain/cover_files.dart';
import '../../platform/state/platform_providers.dart';
import '../state/cover_providers.dart';

/// Cover of a track from the cache folder. Falls back to the placeholder
/// (coloured from [seed]: album key or title) when the key is null, malformed
/// or its file is gone. A valid key whose file is missing is reported once to
/// [coverMissesProvider] so the scanner can extract it again. After the
/// covers are extracted the widget stays on the placeholder until it is
/// rebuilt with a new key or remounted.
class TrackCover extends ConsumerStatefulWidget {
  const TrackCover({
    super.key,
    required this.coverKey,
    required this.seed,
    required this.size,
    required this.dimension,
    this.radius,
    this.circle = false,
  });

  final String? coverKey;
  final String seed;
  final CoverSize size;
  final double dimension;
  final BorderRadius? radius;
  final bool circle;

  @override
  ConsumerState<TrackCover> createState() => _TrackCoverState();
}

class _TrackCoverState extends ConsumerState<TrackCover> {
  File? _file;
  bool _missing = false;
  int _check = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(TrackCover old) {
    super.didUpdateWidget(old);
    if (old.coverKey != widget.coverKey || old.size != widget.size) _resolve();
  }

  void _resolve() {
    final key = widget.coverKey;
    final ticket = ++_check;
    _missing = false;
    if (key == null || !isCoverKey(key)) {
      _file = null;
      return;
    }
    final cache = ref.read(appPathsProvider).cacheDir.path;
    final file = _file = File(
      p.join(cache, coverRelativePath(key, widget.size)),
    );
    // The image is tried at once; this check only reports an evicted file.
    file.exists().then((exists) {
      if (!mounted || ticket != _check || exists) return;
      ref.read(coverMissesProvider).report(key);
      setState(() => _missing = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = _missing ? null : _file;
    return KCover(
      image: file == null ? null : FileImage(file),
      size: widget.dimension,
      placeholderSeed: widget.seed,
      radius: widget.radius,
      circle: widget.circle,
    );
  }
}
