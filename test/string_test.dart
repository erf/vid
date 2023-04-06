import 'dart:math';

import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void info(String str) {
  //print(str);
  //print(str.length);
  //print(str.codeUnits.length);
  print(str.codeUnits);
  print(str.runes.map((e) => toHex(e)).join(' '));
  //print(str.renderWidth);
  print('$str ${str.renderWidth}');
}

String toHex(int value) {
  return '0x${value.toRadixString(16).toUpperCase()}';
}

void main() {
  test('Render width', () {
    expect(''.renderWidth, 0);
    expect('a'.renderWidth, 1);
    expect('▪︎'.renderWidth, 1);
    expect('▪️'.renderWidth, 2);
    expect('❤️'.renderWidth, 2);
    expect('💕'.renderWidth, 2);
    expect('👩‍👩‍👦‍👦'.renderWidth, 2);
    expect('⏳'.renderWidth, 2);
    expect('⌚'.renderWidth, 2);
    expect('⏩'.renderWidth, 2);
  });

  test('Default presentation text', () {
    expect('\u2328'.renderWidth, 1);
    expect('\u23CF'.renderWidth, 1);
    expect('\u23ED'.renderWidth, 1);
    expect('\u23EE'.renderWidth, 1);
    expect('\u23EF'.renderWidth, 1);
    expect('\u23F1'.renderWidth, 1);
    expect('\u23F2'.renderWidth, 1);
    expect('\u23F8'.renderWidth, 1);
    expect('\u23F9'.renderWidth, 1);
    expect('\u23FA'.renderWidth, 1);
  });

  test('Default presentation emoji', () {
    expect('\u231A'.renderWidth, 2);
    expect('\u231B'.renderWidth, 2);
    expect('\u23E9'.renderWidth, 2);
    expect('\u23EA'.renderWidth, 2);
    expect('\u23EB'.renderWidth, 2);
    expect('\u23EC'.renderWidth, 2);
    expect('\u23F0'.renderWidth, 2);
    expect('\u23F3'.renderWidth, 2);
  });
}
