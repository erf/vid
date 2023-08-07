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
    expect(findNextChar(f, cursor, 'a'), Position(c: 3, l: 0));
    expect(findNextChar(f, cursor, 'b'), Position(c: 1, l: 0));
    expect(findNextChar(f, cursor, 'c'), Position(c: 2, l: 0));
  });

  test('motionFindPrevChar', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    final cursor = Position(c: 2, l: 0);
    expect(findPrevChar(f, cursor, 'a'), Position(c: 0, l: 0));
    expect(findPrevChar(f, cursor, 'b'), Position(c: 1, l: 0));
    expect(findPrevChar(f, cursor, 'c'), Position(c: 2, l: 0));
  });
}
