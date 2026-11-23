import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_spinner.dart';

/// The "Đang tìm lời…" state: laid out like a [KEmpty] (hero slot, title, one
/// sentence, centred, scrolls when the text outgrows the space) with a
/// spinner in the icon slot, which [KEmpty] cannot hold. With animations off
/// the spinner is a still arc.
class LyricsSearchingView extends StatelessWidget {
  const LyricsSearchingView({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Centred while it fits, scrolls when the text outgrows the space (large
    // text on a short screen): a shrink-wrapped list inside a Center.
    return Center(
      child: ListView(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.all(KSpace.x6),
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: KSpace.x3,
            children: [
              SizedBox.square(
                dimension: KIconSize.hero,
                child: Padding(
                  padding: const EdgeInsets.all(KSpace.x2),
                  child: LyricsSpinner(
                    size: KIconSize.hero - KSpace.x4,
                    strokeWidth: 3,
                    color: scheme.onSurfaceVariant,
                    label: title,
                  ),
                ),
              ),
              Text(title, textAlign: TextAlign.center, style: text.titleMedium),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
