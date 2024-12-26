import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';
import 'package:vid/terminal.dart';

void main() {
  test('don\'t delete newline at end of file (and create extra newline)', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 3, l: 0);
    e.input('xu');
    expect(f.text, 'abc\n');
    expect(f.cursor, Position(c: 3, l: 0));
  }, skip: true);

  test('don\'t crash when deleting newline at end of file', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 3, l: 0);
    e.input('x');
    expect(f.text, '\n');
    expect(f.cursor, Position(c: 3, l: 0));
  }, skip: true);

  test('delete first char', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'a\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 1, l: 0);
    e.input('xx');
    expect(f.text, '\n');
    expect(f.cursor, Position(c: 0, l: 0));
  }, skip: true);
}
