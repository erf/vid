import 'package:characters/characters.dart';

extension StringExt on String {
  // Try to determine the rendered width of a single character
  int get renderWidth {
    // if the string is empty, return 0
    if (isEmpty) {
      return 0;
    }

    // assert that the string is a single character
    //assert(ch.length <= 1);

    // if the string is a single space, return 1
    if (this == ' ') {
      return 1;
    }

    // if the string is a single tab, return 4
    // if ('\t'.contains(this)) {
    //   return 4;
    // }

    // // if the string is a single newline, return 0
    // if ('\n'.contains(this)) {
    //   return 0;
    // }

    // Check if codeUnits contains a Variation Selector (VS) of type 16 (emoji) or 15 (text)
    // https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
    // http://www.unicode.org/reports/tr51/#def_emoji_presentation
    const int vs15 = 0xFE0E; // text
    if (codeUnits.contains(vs15)) {
      //print('vs15');
      return 1;
    }
    const int vs16 = 0xFE0F; // emoji
    if (codeUnits.contains(vs16)) {
      print('vs16');
      return 2;
    }

    if (codeUnits.length > 1) {
      print('codeUnits.length > 1');
      return 2;
    }

    final int codeUnit = codeUnits.first;

    // Check if codeUnits contains a default presentation emoji or text
    // https://en.wikipedia.org/wiki/Miscellaneous_Technical#References
    const defaultPresentationText = <int>[
      0x2328, // ⌨️
      0x23CF, // ⏏️
      0x23ED, // ⏭️
      0x23EE, // ⏮️
      0x23EF, // ⏯️
      0x23F1, // ⏱️
      0x23F2, // ⏲️
      0x23F8, // ⏸️
      0x23F9, // ⏹️
      0x23FA, // ⏺️
    ];
    if (defaultPresentationText.contains(codeUnit)) {
      print('defaultPresentationText');
      return 1;
    }
    const defaultPresentationEmoji = <int>[
      0x231A, // ⌚
      0x231B, // ⌛
      0x23E9, // ⏩
      0x23EA, // ⏪
      0x23EB, // ⏫
      0x23EC, // ⏬
      0x23F0, // ⏰
      0x23F3, // ⏳
    ];
    if (defaultPresentationEmoji.contains(codeUnit)) {
      print('defaultPresentationEmoji');
      return 2;
    }

    // Return 1 if the first character is in the Basic Multilingual Plane (BMP) else return 2
    // https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane
    if (codeUnit >= 0x10000) {
      print('>= 0x10000');
      return 2;
    } else {
      print('< 0x10000');
      return 1;
    }
  }

  // Shorthand for Characters(this)
  Characters get ch => Characters(this);
}
