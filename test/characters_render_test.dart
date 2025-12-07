import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('takeWhileLessThanRenderedLength', () {
    expect('abc'.renderLineEnd(1), 'a');
    expect('abc'.renderLineEnd(3), 'abc');
    expect('😀😀abc'.renderLineEnd(4), '😀😀');
    expect(
      '😀😀abc'.renderLineEnd(3),
      '😀',
      reason: 'should skip if in middle of emoji',
    );
  });

  test('skipWhileLessThanRenderedLength', () {
    expect('abc'.renderLineStart(1), 'bc');
    expect('abc'.renderLineStart(2), 'c');
    expect('abc'.renderLineStart(3), '');
    expect('😀😀abc'.renderLineStart(4), 'abc');
    expect(
      '😀😀abc'.renderLineStart(3),
      ' abc',
      reason: 'should add space at start if emoji',
    );
  });

  test('skip initial emoji and make space', () {
    expect('😀abc'.renderLineStart(0), '😀abc');
    expect('😀abc'.renderLineStart(1), ' abc');
    expect('😀abc'.renderLineStart(2), 'abc');
    expect('😀abc'.renderLineStart(3), 'bc');
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
    expect('abc'.renderLine(0, 1), 'a');
    expect('abc'.renderLine(0, 3), 'abc');
    expect('❤️‍🔥❤️‍🔥ab'.renderLine(2, 4), '❤️‍🔥ab');
    expect(
      '❤️‍🔥❤️‍🔥ab'.renderLine(3, 4),
      ' ab',
      reason: 'Replace half emoji at start with space',
    );
    expect('abcd🥹'.renderLine(4, 6), '🥹');
    expect('abcd🥹'.renderLine(5, 6), ' ');
    expect(
      'abcd🥹'.renderLine(3, 5),
      'd🥹',
      reason: 'Draw full emoji even if only half indexed',
    );
    expect('abcd🥹'.renderLine(3, 6), 'd🥹');
    expect('abcd🥹'.renderLine(0, 5), 'abcd');
  });

  test('"let\'s combine emojis ❤️❤️😃😃" at col 28 fails', () {
    final text = 'let\'s combine emojis ❤️❤️😃😃';
    final index = 0;
    final width = 28;
    final result = text.renderLine(index, width);
    expect(result, 'let\'s combine emojis ❤️❤️😃');
  });
}
