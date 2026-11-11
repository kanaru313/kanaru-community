import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../playback/ui/track_cover.dart';

/// Picture of a folder: a layered folder (tab and a faded back plate) with a
/// square cover standing out in front of it, offset and shadowed. A folder
/// with no cover is drawn alone, with a solid front plate.
class FolderArt extends StatelessWidget {
  const FolderArt({super.key, this.coverKey, this.seed = ''});

  /// Cover to show; null draws the folder alone.
  final String? coverKey;

  /// Colour seed of the cover placeholder when the file is missing.
  final String seed;

  static const double size = KMediaCard.coverSize;
  static const double _cover = 34;

  @override
  Widget build(BuildContext context) {
    final folder = Theme.of(context).colorScheme.primary;
    final back = folder.withValues(alpha: 0.28);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Positioned(
              left: 2,
              top: 6,
              width: 24,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: back,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 2,
              right: 2,
              top: 12,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: back,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            if (coverKey == null)
              Positioned(
                left: 2,
                right: 2,
                top: 18,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: folder.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              )
            else
              Positioned(
                left: 15,
                top: 16,
                width: _cover,
                height: _cover,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TrackCover(
                    coverKey: coverKey,
                    seed: seed,
                    size: CoverSize.thumb,
                    dimension: _cover,
                    radius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
