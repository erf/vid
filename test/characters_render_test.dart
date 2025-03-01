import 'package:test/test.dart';
import 'package:vid/characters_render.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('takeWhileLessThanRenderedLength', () {
    expect('abc'.ch.renderLineEnd(1).string, 'a');
    expect('abc'.ch.renderLineEnd(3).string, 'abc');
    expect('😀😀abc'.ch.renderLineEnd(4).string, '😀😀');
    expect(
      '😀😀abc'.ch.renderLineEnd(3).string,
      '😀',
      reason: 'should skip if in middle of emoji',
    );
  });

  test('skipWhileLessThanRenderedLength', () {
    expect('abc'.ch.renderLineStart(1).string, 'bc');
    expect('abc'.ch.renderLineStart(2).string, 'c');
    expect('abc'.ch.renderLineStart(3).string, '');
    expect('😀😀abc'.ch.renderLineStart(4).string, 'abc');
    expect(
      '😀😀abc'.ch.renderLineStart(3).string,
      ' abc',
      reason: 'should add space at start if emoji',
    );
  });

  test('skip initial emoji and make space', () {
    expect('😀abc'.ch.renderLineStart(0).string, '😀abc');
    expect('😀abc'.ch.renderLineStart(1).string, ' abc');
    expect('😀abc'.ch.renderLineStart(2).string, 'abc');
    expect('😀abc'.ch.renderLineStart(3).string, 'bc');
  });

  test('renderedLength', () {
    expect('abc'.ch.renderLength(0), 0);
    expect('abc'.ch.renderLength(2), 2);
    expect('abc'.ch.renderLength(3), 3);
    expect('😀😀abc'.ch.renderLength(1), 2);
    expect('😀😀abc'.ch.renderLength(4), 6);
    expect('😀😀abc'.ch.renderLength(5), 7);
  });

  test('renderLine', () {
    expect('abc'.ch.renderLine(0, 1).string, 'a');
    expect('abc'.ch.renderLine(0, 3).string, 'abc');
    expect('❤️‍🔥❤️‍🔥ab'.ch.renderLine(2, 4).string, '❤️‍🔥ab');
    expect(
      '❤️‍🔥❤️‍🔥ab'.ch.renderLine(3, 4).string,
      ' ab',
      reason: 'Replace half emoji at start with space',
    );
    expect('abcd🥹'.ch.renderLine(4, 6).string, '🥹');
    expect('abcd🥹'.ch.renderLine(5, 6).string, ' ');
    expect(
      'abcd🥹'.ch.renderLine(3, 5).string,
      'd🥹',
      reason: 'Draw full emoji even if only half indexed',
    );
    expect('abcd🥹'.ch.renderLine(3, 6).string, 'd🥹');
    expect('abcd🥹'.ch.renderLine(0, 5).string, 'abcd');
  });

  test('"let\'s combine emojis ❤️❤️😃😃" at col 28 fails', () {
    final text = 'let\'s combine emojis ❤️❤️😃😃';
    final index = 0;
    final width = 28;
    final result = text.ch.renderLine(index, width);
    expect(result.string, 'let\'s combine emojis ❤️❤️😃');
  });
}
