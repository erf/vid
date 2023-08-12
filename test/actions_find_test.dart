import 'package:test/test.dart';
import 'package:vid/actions_find.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';

void main() {
  test('motionFindNextChar', () {
    final f = FileBuffer();
    f.text = 'abca\ndef\n';
    f.createLines();
    final cursor = Position(c: 0, l: 0);
    expect(findNextChar(f, cursor, 'a', false), Position(c: 3, l: 0));
    expect(findNextChar(f, cursor, 'b', false), Position(c: 1, l: 0));
    expect(findNextChar(f, cursor, 'c', false), Position(c: 2, l: 0));
    // inclusive
    expect(findNextChar(f, cursor, 'a', true), Position(c: 4, l: 0));
    expect(findNextChar(f, cursor, 'b', true), Position(c: 2, l: 0));
    expect(findNextChar(f, cursor, 'c', true), Position(c: 3, l: 0));
  });

  test('motionFindPrevChar', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    final cursor = Position(c: 2, l: 0);
    expect(findPrevChar(f, cursor, 'a', false), Position(c: 0, l: 0));
    expect(findPrevChar(f, cursor, 'b', false), Position(c: 1, l: 0));
    expect(findPrevChar(f, cursor, 'c', false), Position(c: 2, l: 0));
  });
}
