import 'package:test/test.dart';
import 'package:vid/characters_ext.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('take rendered characters', () {
    expect('abc'.ch.takeWhileLessThanRenderedLength(1).string, 'a');
    expect('abc'.ch.takeWhileLessThanRenderedLength(3).string, 'abc');
    expect('😀😀abc'.ch.takeWhileLessThanRenderedLength(4).string, '😀😀');
  });
  test('skip rendered characters', () {
    expect('abc'.ch.skipWhileLessThanRenderedLength(1).string, 'bc');
    expect('abc'.ch.skipWhileLessThanRenderedLength(2).string, 'c');
    expect('abc'.ch.skipWhileLessThanRenderedLength(3).string, '');
    expect('😀😀abc'.ch.skipWhileLessThanRenderedLength(4).string, 'abc');
  });
}
