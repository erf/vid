import 'package:test/test.dart';
import 'package:vid/grapheme/unicode.dart';
import 'package:vid/string_ext.dart';

void main() {
  const int tabWidth = 4;

  test('Emoji render width', () {
    expect(''.charWidth(tabWidth), 0);
    expect('a'.charWidth(tabWidth), 1);
    expect('▪︎'.charWidth(tabWidth), 1);
    expect('▪️'.charWidth(tabWidth), 2);
    expect('❤️'.charWidth(tabWidth), 2);
    expect('💕'.charWidth(tabWidth), 2);
    expect('👩‍👩‍👦‍👦'.charWidth(tabWidth), 2);
    expect('⏳'.charWidth(tabWidth), 2);
    expect('⌚'.charWidth(tabWidth), 2);
    expect('⏩'.charWidth(tabWidth), 2);
  });

  test('Default presentation text', () {
    expect('⌨'.charWidth(tabWidth), 1);
    expect('⏏'.charWidth(tabWidth), 1);
    expect('⏭'.charWidth(tabWidth), 1);
    expect('⏮'.charWidth(tabWidth), 1);
    expect('⏯'.charWidth(tabWidth), 1);
    expect('⏱'.charWidth(tabWidth), 1);
    expect('⏲'.charWidth(tabWidth), 1);
    expect('⏸'.charWidth(tabWidth), 1);
  });

  test('Default presentation emoji', () {
    expect('⌚'.charWidth(tabWidth), 2);
    expect('⌛'.charWidth(tabWidth), 2);
    expect('⏩'.charWidth(tabWidth), 2);
    expect('⏪'.charWidth(tabWidth), 2);
    expect('⏫'.charWidth(tabWidth), 2);
    expect('⏬'.charWidth(tabWidth), 2);
    expect('⏰'.charWidth(tabWidth), 2);
    expect('⏳'.charWidth(tabWidth), 2);
  });

  test('Emoji vs Text types with variations', () {
    expect('⌛'.charWidth(tabWidth), 2, reason: '⌛ emoji');
    expect('⌛︎'.charWidth(tabWidth), 1, reason: '⌛ emoji + VS15');
    expect('⌛️'.charWidth(tabWidth), 2, reason: '⌛ emoji + VS16');
    expect('⌨'.charWidth(tabWidth), 1, reason: '⌨ text');
    expect('⌨︎'.charWidth(tabWidth), 1, reason: '⌨︎ text + VS15');
    expect('⌨️'.charWidth(tabWidth), 2, reason: '⌨️ text + VS16');
  });

  test('test EastAsianWidth, english vs chinese characters', () {
    expect('h'.charWidth(tabWidth), 1);
    expect('X'.charWidth(tabWidth), 1);
    expect('吉'.charWidth(tabWidth), 2);
    expect('龍'.charWidth(tabWidth), 2);
  });

  test('codePoint value of a', () {
    String char = 'a';
    int len = char.codeUnits.length;
    int val = char.codeUnitAt(0);
    expect(len, 1);
    expect(val, 97);
  });

  test('codePoint value of ❤️', () {
    String char = '❤️';
    int len = char.codeUnits.length;
    int val = char.codeUnitAt(0);
    expect(len, 2);
    expect(val, 10084);
  });

  test('codePoint value of ❤️‍🔥', () {
    String char = '❤️‍🔥';
    int len = char.codeUnits.length;
    int val = char.codeUnitAt(0);
    expect(len, 5);
    expect(val, 10084);
  });

  test('char width of 🇳🇴', () {
    expect('🇳🇴'.charWidth(tabWidth), 2);
  });

  test('char width of 8️⃣', () {
    expect('8️⃣'.charWidth(tabWidth), 2);
  });

  test('char width of ⑧', () {
    expect('⑧'.charWidth(tabWidth), 1);
  });

  test('tab width', () {
    expect('\t'.charWidth(tabWidth), tabWidth);
    expect('\t'.charWidth(8), 8);
  });

  test('control chars have zero width', () {
    expect('\x07'.charWidth(tabWidth), 0, reason: 'bell');
    expect('\x1B'.charWidth(tabWidth), 0, reason: 'escape');
    expect('\x7F'.charWidth(tabWidth), 0, reason: 'delete');
    expect('\x85'.charWidth(tabWidth), 0, reason: 'C1 next-line');
    expect('\x9F'.charWidth(tabWidth), 0, reason: 'C1 end');
  });

  test('Latin-1 chars have width 1', () {
    expect('é'.charWidth(tabWidth), 1);
    expect('ü'.charWidth(tabWidth), 1);
    expect('°'.charWidth(tabWidth), 1);
    expect('±'.charWidth(tabWidth), 1);
    expect('©'.charWidth(tabWidth), 1);
  });

  test('zero-width code points have width 0', () {
    expect('\u0301'.charWidth(tabWidth), 0, reason: 'combining acute');
    expect('\u200B'.charWidth(tabWidth), 0, reason: 'ZWSP');
    expect('\u200D'.charWidth(tabWidth), 0, reason: 'ZWJ standalone');
    expect('\uFE0F'.charWidth(tabWidth), 0, reason: 'VS16 standalone');
  });

  test('codePointWidth matches table across planes', () {
    // Spot-check the 2-stage table against known values across all planes.
    final cases = <int, int>{
      0x0041: 1, // A
      0x00E9: 1, // é
      0x0301: 0, // combining acute
      0x200D: 0, // ZWJ
      0x231B: 2, // ⌛ emoji presentation
      0x2328: 1, // ⌨ text presentation
      0x5409: 2, // 吉 CJK
      0x1F495: 2, // 💕
      0x1F1F3: 2, // regional indicator N (emoji presentation)
      0x20000: 2, // plane 2 (defaults wide)
      0xE0001: 0, // tag (Cf format)
    };
    cases.forEach((cp, expected) {
      expect(
        Unicode.codePointWidth(cp),
        expected,
        reason: 'U+${cp.toRadixString(16).toUpperCase()}',
      );
    });
  });
}
