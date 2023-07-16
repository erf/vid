import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('String info', () {
    'a'.info();
    '❤️'.info();
    '😵'.info();
    '👩‍👩‍👦‍👦'.info();
  }, skip: true);

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
    expect('⌨'.renderWidth, 1);
    expect('⏏'.renderWidth, 1);
    expect('⏭'.renderWidth, 1);
    expect('⏮'.renderWidth, 1);
    expect('⏯'.renderWidth, 1);
    expect('⏱'.renderWidth, 1);
    expect('⏲'.renderWidth, 1);
    expect('⏸'.renderWidth, 1);
  });

  test('Default presentation emoji', () {
    expect('⌚'.renderWidth, 2);
    expect('⌛'.renderWidth, 2);
    expect('⏩'.renderWidth, 2);
    expect('⏪'.renderWidth, 2);
    expect('⏫'.renderWidth, 2);
    expect('⏬'.renderWidth, 2);
    expect('⏰'.renderWidth, 2);
    expect('⏳'.renderWidth, 2);
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
