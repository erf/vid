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

  test('get rendered length', () {
    expect('abc'.ch.renderedLength(0), 0);
    expect('abc'.ch.renderedLength(2), 2);
    expect('abc'.ch.renderedLength(3), 3);
    expect('😀😀abc'.ch.renderedLength(1), 2);
    expect('😀😀abc'.ch.renderedLength(4), 6);
    expect('😀😀abc'.ch.renderedLength(5), 7);
  });
}
