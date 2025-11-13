import 'package:test/test.dart';
import 'package:vid/characters_render.dart';
import 'package:vid/string_ext.dart';

void main() {
  int tabWidth = 4;

  test('takeWhileLessThanRenderedLength', () {
    expect('abc'.ch.renderLineEnd(1, tabWidth).string, 'a');
    expect('abc'.ch.renderLineEnd(3, tabWidth).string, 'abc');
    expect('😀😀abc'.ch.renderLineEnd(4, tabWidth).string, '😀😀');
    expect(
      '😀😀abc'.ch.renderLineEnd(3, tabWidth).string,
      '😀',
      reason: 'should skip if in middle of emoji',
    );
  });

  test('skipWhileLessThanRenderedLength', () {
    expect('abc'.ch.renderLineStart(1, tabWidth).string, 'bc');
    expect('abc'.ch.renderLineStart(2, tabWidth).string, 'c');
    expect('abc'.ch.renderLineStart(3, tabWidth).string, '');
    expect('😀😀abc'.ch.renderLineStart(4, tabWidth).string, 'abc');
    expect(
      '😀😀abc'.ch.renderLineStart(3, tabWidth).string,
      ' abc',
      reason: 'should add space at start if emoji',
    );
  });

  test('skip initial emoji and make space', () {
    expect('😀abc'.ch.renderLineStart(0, tabWidth).string, '😀abc');
    expect('😀abc'.ch.renderLineStart(1, tabWidth).string, ' abc');
    expect('😀abc'.ch.renderLineStart(2, tabWidth).string, 'abc');
    expect('😀abc'.ch.renderLineStart(3, tabWidth).string, 'bc');
  });

  test('renderedLength', () {
    expect('abc'.ch.renderLength(0, tabWidth), 0);
    expect('abc'.ch.renderLength(2, tabWidth), 2);
    expect('abc'.ch.renderLength(3, tabWidth), 3);
    expect('😀😀abc'.ch.renderLength(1, tabWidth), 2);
    expect('😀😀abc'.ch.renderLength(4, tabWidth), 6);
    expect('😀😀abc'.ch.renderLength(5, tabWidth), 7);
  });

  test('renderLine', () {
    expect('abc'.ch.renderLine(0, 1, tabWidth).string, 'a');
    expect('abc'.ch.renderLine(0, 3, tabWidth).string, 'abc');
    expect('❤️‍🔥❤️‍🔥ab'.ch.renderLine(2, 4, tabWidth).string, '❤️‍🔥ab');
    expect(
      '❤️‍🔥❤️‍🔥ab'.ch.renderLine(3, 4, tabWidth).string,
      ' ab',
      reason: 'Replace half emoji at start with space',
    );
    expect('abcd🥹'.ch.renderLine(4, 6, tabWidth).string, '🥹');
    expect('abcd🥹'.ch.renderLine(5, 6, tabWidth).string, ' ');
    expect(
      'abcd🥹'.ch.renderLine(3, 5, tabWidth).string,
      'd🥹',
      reason: 'Draw full emoji even if only half indexed',
    );
    expect('abcd🥹'.ch.renderLine(3, 6, tabWidth).string, 'd🥹');
    expect('abcd🥹'.ch.renderLine(0, 5, tabWidth).string, 'abcd');
  });

  test('"let\'s combine emojis ❤️❤️😃😃" at col 28 fails', () {
    final text = 'let\'s combine emojis ❤️❤️😃😃';
    final index = 0;
    final width = 28;
    final result = text.ch.renderLine(index, width, tabWidth);
    expect(result.string, 'let\'s combine emojis ❤️❤️😃');
  });
}
