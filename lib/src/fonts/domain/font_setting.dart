import '../../platform/domain/setting.dart';
import 'app_font.dart';
import 'builtin_fonts.dart';

/// Id of the font used for all app text.
final fontSetting = Setting<String>(
  'app.font',
  defaultFontId,
  decode: (json) {
    if (json is String && isValidFontId(json)) return json;
    throw FormatException('invalid font id: $json');
  },
  encode: (value) => value,
);
