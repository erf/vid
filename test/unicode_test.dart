import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('Emoji render width', () {
    expect(''.charWidth, 0);
    expect('a'.charWidth, 1);
    expect('▪︎'.charWidth, 1);
    expect('▪️'.charWidth, 2);
    expect('❤️'.charWidth, 2);
    expect('💕'.charWidth, 2);
    expect('👩‍👩‍👦‍👦'.charWidth, 2);
    expect('⏳'.charWidth, 2);
    expect('⌚'.charWidth, 2);
    expect('⏩'.charWidth, 2);
  });

  test('Default presentation text', () {
    expect('⌨'.charWidth, 1);
    expect('⏏'.charWidth, 1);
    expect('⏭'.charWidth, 1);
    expect('⏮'.charWidth, 1);
    expect('⏯'.charWidth, 1);
    expect('⏱'.charWidth, 1);
    expect('⏲'.charWidth, 1);
    expect('⏸'.charWidth, 1);
  });

  test('Default presentation emoji', () {
    expect('⌚'.charWidth, 2);
    expect('⌛'.charWidth, 2);
    expect('⏩'.charWidth, 2);
    expect('⏪'.charWidth, 2);
    expect('⏫'.charWidth, 2);
    expect('⏬'.charWidth, 2);
    expect('⏰'.charWidth, 2);
    expect('⏳'.charWidth, 2);
  });

  test('Emoji vs Text types with variations', () {
    expect('⌛'.charWidth, 2, reason: '⌛ emoji');
    expect('⌛︎'.charWidth, 1, reason: '⌛ emoji + VS15');
    expect('⌛️'.charWidth, 2, reason: '⌛ emoji + VS16');
    expect('⌨'.charWidth, 1, reason: '⌨ text');
    expect('⌨︎'.charWidth, 1, reason: '⌨︎ text + VS15');
    expect('⌨️'.charWidth, 2, reason: '⌨️ text + VS16');
  });

  test('test EastAsianWidth, english vs chinese characters', () {
    expect('h'.charWidth, 1);
    expect('X'.charWidth, 1);
    expect('吉'.charWidth, 2);
    expect('龍'.charWidth, 2);
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
    expect('🇳🇴'.charWidth, 2);
  });

  test('char width of 8️⃣', () {
    expect('8️⃣'.charWidth, 2);
  });

  test('char width of ⑧', () {
    expect('⑧'.charWidth, 1);
  });
}
