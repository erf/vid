import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('joinLines', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(x: 0, y: 1);
    final e = Editor();
    actionJoinLines(e, f);
    expect(f.lines, [
      'abc'.ch,
      'defghi'.ch,
    ]);
    expect(f.cursor, Position(x: 0, y: 1));
  });

  test('deleteLineEnd', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(x: 0, y: 1);
    final e = Editor();
    actionDeleteLineEnd(e, f);
    expect(f.lines, [
      'abc'.ch,
      ''.ch,
      'ghi'.ch,
    ]);
    expect(f.cursor, Position(x: 0, y: 1));
  });
}
