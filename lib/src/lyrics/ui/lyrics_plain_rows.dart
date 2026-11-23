import 'package:material_ui/material_ui.dart';

/// Lets `KListRow`s read as plain rows on a dialog or sheet surface: the row
/// fills with `surfaceContainerLow`, which shows as a box there, so this
/// scope makes that fill transparent. Rows keep their own tint when selected.
class LyricsPlainRows extends StatelessWidget {
  const LyricsPlainRows({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme
          .copyWith(surfaceContainerLow: Colors.transparent),
    ),
    child: child,
  );
}
