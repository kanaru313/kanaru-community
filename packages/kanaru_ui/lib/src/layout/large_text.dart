import 'package:material_ui/material_ui.dart';

/// True from 200 % text scale (tested at 1.99 to absorb rounding). The one
/// rule widgets use to switch to their large-text layout.
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.99;
