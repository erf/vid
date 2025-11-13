import 'dart:math';

const numOfChars = 1000000;

List<String> genRandomUnicodeChars(int length) {
  final r = Random();
  return .generate(length, (i) => .fromCharCode(r.nextInt(0x10FFFF + 1)));
}
