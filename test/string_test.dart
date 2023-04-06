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
    expect('⏩'.renderWidth, 2);
  });
}
