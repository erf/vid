import 'package:test/test.dart';
import 'package:vid/string_ext.dart';
import 'package:vid/int_ext.dart';

void info(String str) {
  print(str);
  print(str.length);
  print(str.codeUnits.length);
  print(str.codeUnits);
  print(str.runes.map((e) => e.hex).join(' '));
  print(str.renderWidth);
  print('$str ${str.renderWidth}');
}

void main() {
  test('Emoji render width', () {
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

  test('Emoji vs Text types with variations', () {
    expect('⌛'.renderWidth, 2, reason: '⌛ emoji');
    expect('⌛︎'.renderWidth, 1, reason: '⌛ emoji + VS15');
    expect('⌛️'.renderWidth, 2, reason: '⌛ emoji + VS16');
    expect('⌨'.renderWidth, 1, reason: '⌨ text');
    expect('⌨︎'.renderWidth, 1, reason: '⌨︎ text + VS15');
    expect('⌨️'.renderWidth, 2, reason: '⌨️ text + VS16');
  });
}
