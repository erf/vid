import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';

void main() {
  test('joinLines', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    e.input('J', redraw: false);
    expect(f.text, 'abc\ndefghi\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('actionDeleteLineEnd', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('D', redraw: false);
    expect(f.text, 'abc\nd\nghi\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionChangeLineEnd', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'hello world\n';
    f.createLines();
    f.cursor = Position(c: 5, l: 0);
    e.input('C', redraw: false);
    expect(f.text, 'hello\n');
  });

  test('actionDeleteCharNext', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('x', redraw: false);
    expect(f.text, 'abc\ndf\nghi\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionDeleteCharNext delete newline', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(l: 0, c: 3);
    e.input('x', redraw: false);
    expect(f.text, 'abcdef\n');
    expect(f.cursor, Position(l: 0, c: 3));
  });

  test('actionInsertLineStart', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(c: 2, l: 1);
    e.input('I', redraw: false);
    e.input('x', redraw: false);
    expect(f.text, 'abc\nxdef\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionAppendLineEnd', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('A', redraw: false);
    e.input('x', redraw: false);
    expect(f.text, 'abcx\ndef\n');
  });

  test('actionAppendCharNext', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(c: 3, l: 0);
    e.input('a', redraw: false);
    e.input('x', redraw: false);
    expect(f.text, 'abcx\ndef\n');
  });

  test('cursorLineBottomOrCount G', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('G', redraw: false);
    expect(f.cursor, Position(c: 0, l: 2));
  });

  test('cursorLineBottomOrCount 2G', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('2', redraw: false);
    e.input('G', redraw: false);
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('cursorLineTopOrCount gg', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 2);
    e.input('g', redraw: false);
    e.input('g', redraw: false);
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('cursorLineTopOrCount 2gg', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 2);
    e.input('2', redraw: false);
    e.input('g', redraw: false);
    e.input('g', redraw: false);
    expect(f.cursor, Position(c: 0, l: 1));
  });
}
