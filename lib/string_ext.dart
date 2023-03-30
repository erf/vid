import 'package:string_width/string_width.dart';

import 'config.dart';

extension StringExt on String {
  int get renderWidth {
    if (Config.useLatestUnicodeVersion) {
      return stringWidth(this);
    } else {
      // https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane
      return runes.first > 0x10000 ? 2 : 1;
    }
  }
}
