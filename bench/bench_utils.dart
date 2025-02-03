import 'dart:math';

const numOfChars = 1000000;

List<String> genRandomUnicodeChars(int length) {
  final rand = Random();
  return List.generate(
    length,
    (i) => String.fromCharCode(rand.nextInt(0x10FFFF + 1)),
  );
}
