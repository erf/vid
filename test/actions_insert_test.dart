import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/modes.dart';
import 'package:vid/position.dart';

void main() {
  test('defaultInsert', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 0);
    e.input('i', redraw: false);
    e.input('d', redraw: false);
    expect(f.text, 'adbc\n');
    expect(f.cursor, Position(c: 2, l: 0));
  });

  test('insertActionEscape', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('i', redraw: false);
    e.input('\x1b', redraw: false);
    expect(f.mode, Mode.normal);
  });

  test('insertActionEnter', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abcdef\n';
    f.createLines();
    f.cursor = Position(c: 3, l: 0);
    e.input('i', redraw: false);
    e.input('\n', redraw: false);
    expect(f.text, 'abc\ndef\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('insertActionBackspace', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    e.insert('\x7f');
    expect(f.text, 'abcdef\nghi\n');
    expect(f.cursor, Position(c: 3, l: 0));
  });
}
