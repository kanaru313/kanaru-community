import 'package:flutter/widgets.dart';

import '../tokens/k_layout.dart';

/// Which shell the window is big enough for. Reading the width to pick a
/// layout is allowed only here, in kanaru_ui and in `shell/`.
enum FormFactor {
  mobile,
  desktop;

  static FormFactor fromWidth(double width) =>
      width >= KBreakpoints.desktop ? desktop : mobile;

  static FormFactor of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}
