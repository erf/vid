import 'dart:developer';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/unicode_info.dart';

import 'unicode_info_ext.dart';

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

    // If the string is a emoji, return 2
    if (UnicodeInfoExt.isEmoji(ch)) {
      //print('emojiCodePoints1: $this');
      return 2;
    }

    //print('text: $this');
    return 1;
  }

  // Shorthand for Characters(this)
  Characters get ch => Characters(this);
}
