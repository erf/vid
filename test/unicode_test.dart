import 'package:test/test.dart';
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
}
