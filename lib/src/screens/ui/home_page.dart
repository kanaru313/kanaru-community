import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../library/state/scan/scan_startup.dart';
import '../../library/ui/scan/scan_progress_card.dart';

/// Home: the scan card on top of the (still empty) page.
///
/// After its first frame it asks the scanner for its startup work (the
/// incremental scan and the garbage collection). The trigger lives here
/// because Home is the first page after setup; a feature that opens another
/// page first (restoring the last tab, a deep link) must call
/// `scanStartupWorkProvider` too.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(scanStartupWorkProvider)();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KPage(
      children: [
        PageHeader(title: l10n.navHome),
        const ScanProgressCard(),
        SizedBox(
          height: _emptyHeight,
          child: KEmpty(icon: KIcons.home, message: l10n.emptyHome),
        ),
      ],
    );
  }

  /// Keeps the empty message in the upper middle of the page, as the
  /// full-height empty page did.
  static const double _emptyHeight = 360;
}
