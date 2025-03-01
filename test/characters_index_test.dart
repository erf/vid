import 'package:test/test.dart';
import 'package:vid/characters_index.dart';
import 'package:vid/string_ext.dart';

void main() {
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
      'a👩‍👩‍👦‍👦👩‍👩‍👦‍👦f'.ch.removeRange(0, 2).string,
      '👩‍👩‍👦‍👦f',
    );
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
}
