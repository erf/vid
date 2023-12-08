import 'package:test/test.dart';
import 'package:vid/characters_render.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('takeWhileLessThanRenderedLength', () {
    expect('abc'.ch.takeWhileLessThanRenderedLength(1).string, 'a');
    expect('abc'.ch.takeWhileLessThanRenderedLength(3).string, 'abc');
    expect('😀😀abc'.ch.takeWhileLessThanRenderedLength(4).string, '😀😀');
  });
  test('skipWhileLessThanRenderedLength', () {
    expect('abc'.ch.skipWhileLessThanRenderedLength(1).string, 'bc');
    expect('abc'.ch.skipWhileLessThanRenderedLength(2).string, 'c');
    expect('abc'.ch.skipWhileLessThanRenderedLength(3).string, '');
    expect('😀😀abc'.ch.skipWhileLessThanRenderedLength(4).string, 'abc');
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
    expect('❤️‍🔥❤️‍🔥ab'.ch.renderLine(3, 4).string, ' ab',
        reason: 'Replace half emoji at start with space');
    expect('abcd🥹'.ch.renderLine(4, 6).string, '🥹');
    expect('abcd🥹'.ch.renderLine(5, 6).string, ' ');
    expect('abcd🥹'.ch.renderLine(3, 5).string, 'd🥹',
        reason: 'Draw full emoji even if only half indexed');
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
