import 'dart:math';

import 'package:characters/characters.dart';
import 'package:test/test.dart';
import 'package:vid/characters_ext.dart';
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
    expect('abc'.ch.renderedLength(0), 0);
    expect('abc'.ch.renderedLength(2), 2);
    expect('abc'.ch.renderedLength(3), 3);
    expect('😀😀abc'.ch.renderedLength(1), 2);
    expect('😀😀abc'.ch.renderedLength(4), 6);
    expect('😀😀abc'.ch.renderedLength(5), 7);
  });

  test('getRenderLine', () {
    expect('abc'.ch.getRenderLine(0, 1).string, 'a');
    expect('abc'.ch.getRenderLine(0, 3).string, 'abc');
    expect('❤️‍🔥❤️‍🔥ab'.ch.getRenderLine(2, 4).string, '❤️‍🔥ab');
    expect('❤️‍🔥❤️‍🔥ab'.ch.getRenderLine(3, 4).string, ' ab',
        reason: 'Replace half emoji at start with space');
    expect('abcd🥹'.ch.getRenderLine(4, 6).string, '🥹');
    expect('abcd🥹'.ch.getRenderLine(5, 6).string, ' ');
    expect('abcd🥹'.ch.getRenderLine(3, 5).string, 'd🥹',
        reason: 'Draw full emoji even if only half indexed');
    expect('abcd🥹'.ch.getRenderLine(3, 6).string, 'd🥹');
    expect('abcd🥹'.ch.getRenderLine(0, 5).string, 'abcd🥹');
  });

  test('substring', () {
    expect('abc'.ch.substring(0, 1).string, 'a');
    expect('abc'.ch.substring(0, 2).string, 'ab');
    expect('abc'.ch.substring(0, 3).string, 'abc');
    expect('😀😀abc'.ch.substring(0, 1).string, '😀');
    expect('😀😀abc'.ch.substring(0, 2).string, '😀😀');
    expect('😀😀abc'.ch.substring(0, 3).string, '😀😀a');
  });

  test('replaceRange', () {
    expect('abc'.ch.replaceRange(0, 1, 'd'.ch).string, 'dbc');
    expect('abc'.ch.replaceRange(0, 3, 'cba'.ch).string, 'cba');
    expect('abcdef'.ch.replaceRange(1, 5, '👑👑'.ch).string, 'a👑👑f');
  });

  test('removeRange', () {
    expect('abc'.ch.removeRange(0, 1).string, 'bc');
    expect('abc'.ch.removeRange(0, 3).string, '');
    expect('abcdef'.ch.removeRange(1, 5).string, 'af');
    expect(
        'a👩‍👩‍👦‍👦👩‍👩‍👦‍👦f'.ch.removeRange(0, 2).string, '👩‍👩‍👦‍👦f');
  });

  test('deleteCharAt', () {
    expect('abc'.ch.deleteCharAt(0).string, 'bc');
    expect('abc'.ch.deleteCharAt(1).string, 'ac');
    expect('abc'.ch.deleteCharAt(2).string, 'ab');
    expect('abc'.ch.deleteCharAt(3).string, 'abc');
    expect('😀😀abc'.ch.deleteCharAt(0).string, '😀abc');
    expect('😀😀abc'.ch.deleteCharAt(1).string, '😀abc');
    expect('😀😀abc'.ch.deleteCharAt(2).string, '😀😀bc');
    expect('😀😀abc'.ch.deleteCharAt(3).string, '😀😀ac');
    expect('😀😀abc'.ch.deleteCharAt(4).string, '😀😀ab');
  });

  test('replaceCharAt', () {
    expect('abc'.ch.replaceCharAt(0, 'd'.ch).string, 'dbc');
    expect('abc'.ch.replaceCharAt(1, 'd'.ch).string, 'adc');
    expect('abc'.ch.replaceCharAt(2, 'd'.ch).string, 'abd');
    expect('abc'.ch.replaceCharAt(3, 'd'.ch).string, 'abcd');
    expect('😀😀abc'.ch.replaceCharAt(0, 'd'.ch).string, 'd😀abc');
    expect('😀😀abc'.ch.replaceCharAt(1, 'd'.ch).string, '😀dabc');
  });

  test('CharacterRange methods', () {
    final source = 'abc def ghi';
    final range = CharacterRange(source);
    expect(range.current, '');
    range.moveNext(7);
    expect(range.current, 'abc def');
    range.collapseToLast('def'.ch);
    expect(range.current, 'def');
    range.expandBackAll();
    expect(range.current, 'abc def');
    range.dropFirst(4);
    expect(range.current, 'def');
    expect(range.source.string, 'abc def ghi');
    range.dropLast(3);
    expect(range.current, '');
    range.moveBack();
    range.moveBackAll();
    expect(range.current, 'abc');
    range.expandAll();
    expect(range.current, 'abc def ghi');
  });
}
