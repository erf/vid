import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';

void main() {
  test('move cursor by word 3 times', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc def ghi jkl\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('3w', redraw: false);
    expect(f.cursor, Position(c: 12, l: 0));
  });

  test('delete word 3 times', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc def ghi jkl\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('3dw', redraw: false);
    expect(f.cursor, Position(c: 0, l: 0));
    expect(f.text, 'jkl\n');
  });
}
