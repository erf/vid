import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('renderLine end boundary', () {
    expect('abc'.visibleLine(0, 1), 'a');
    expect('abc'.visibleLine(0, 3), 'abc');
    expect('😀😀abc'.visibleLine(0, 4), '😀😀');
    expect(
      '😀😀abc'.visibleLine(0, 3),
      '😀',
      reason: 'should drop wide char straddling the right edge',
    );
  });

  test('renderLine start boundary (horizontal scroll)', () {
    expect('abc'.visibleLine(1, 80), 'bc');
    expect('abc'.visibleLine(2, 80), 'c');
    expect('abc'.visibleLine(3, 80), '');
    expect('😀😀abc'.visibleLine(4, 80), 'abc');
    expect(
      '😀😀abc'.visibleLine(3, 80),
      ' abc',
      reason: 'should add space at start if emoji is split',
    );
  });

  test('skip initial emoji and make space', () {
    expect('😀abc'.visibleLine(0, 80), '😀abc');
    expect('😀abc'.visibleLine(1, 80), ' abc');
    expect('😀abc'.visibleLine(2, 80), 'abc');
    expect('😀abc'.visibleLine(3, 80), 'bc');
  });

  test('renderedLength', () {
    expect('abc'.renderLength(), 3);
    expect('😀😀abc'.renderLength(), 7); // 2+2+1+1+1
    expect(''.renderLength(), 0);
    expect('hello world'.renderLength(), 11);
    // With tabs
    expect('\t'.renderLength(4), 4);
    expect('a\tb'.renderLength(4), 6); // 1+4+1
  });

  test('renderLine', () {
    expect('abc'.visibleLine(0, 1), 'a');
    expect('abc'.visibleLine(0, 3), 'abc');
    expect('❤️‍🔥❤️‍🔥ab'.visibleLine(2, 4), '❤️‍🔥ab');
    expect(
      '❤️‍🔥❤️‍🔥ab'.visibleLine(3, 4),
      ' ab',
      reason: 'Replace half emoji at start with space',
    );
    expect('abcd🥹'.visibleLine(4, 6), '🥹');
    expect('abcd🥹'.visibleLine(5, 6), ' ');
    expect(
      'abcd🥹'.visibleLine(3, 5),
      'd🥹',
      reason: 'Draw full emoji even if only half indexed',
    );
    expect('abcd🥹'.visibleLine(3, 6), 'd🥹');
    expect('abcd🥹'.visibleLine(0, 5), 'abcd');
  });

  test('"let\'s combine emojis ❤️❤️😃😃" at col 28 fails', () {
    final text = 'let\'s combine emojis ❤️❤️😃😃';
    final index = 0;
    final width = 28;
    final result = text.visibleLine(index, width);
    expect(result, 'let\'s combine emojis ❤️❤️😃');
  });
}
