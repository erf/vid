import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_lines.dart';
import 'package:vid/position.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('actionDeleteLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 1, l: 1);
    e.input('D');
    expect(f.text, 'abc\nd\nghi\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionChangeLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello world\n';
    f.createLines(e);
    f.cursor = Position(c: 5, l: 0);
    e.input('C');
    expect(f.text, 'hello\n');
  });

  test('actionDeleteCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 1, l: 1);
    e.input('x');
    expect(f.text, 'abc\ndf\nghi\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionDeleteCharNext delete newline', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    f.cursor = Position(l: 0, c: 3);
    e.input('x');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, Position(l: 0, c: 3));
  });

  test('actionInsertLineStart', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    f.cursor = Position(c: 2, l: 1);
    e.input('Ix');
    expect(f.text, 'abc\nxdef\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionAppendLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('Ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('actionAppendCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    f.cursor = Position(c: 3, l: 0);
    e.input('ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('cursorLineBottomOrCount G', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('G');
    expect(f.cursor, Position(c: 0, l: 2));
  });

  test('cursorLineBottomOrCount 2G', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('2G');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('cursorLineTopOrCount gg', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 2);
    e.input('gg');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('cursorLineTopOrCount 2gg', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 2);
    e.input('2gg');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('repeat dw.', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    e.input('dw.');
    expect(f.text, 'ghi\n');
  });

  test('repeat twice dw..', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    f.createLines(e);
    e.input('dw..');
    expect(f.text, 'jkl\n');
  });

  test('repeat find fc;;', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc abc abc abc\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    f.edit.findStr = 'c';
    e.input('f;;');
    expect(f.cursor, Position(c: 10, l: 0));
  });

  test('delete line, move down and paste', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
    expect(f.cursor, Position(c: 0, l: 2));
  });

  test('joining lines', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('J');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('joining lines with empty line', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n\ndef\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('JJ');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('increase next number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc 123 def\n';
    f.createLines(e);
    e.input('\u0001');
    expect(f.text, 'abc 124 def\n');
    expect(f.cursor.c, 6);
  });

  test('increase negative number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc -123 def\n';
    f.createLines(e);
    e.input('\u0001');
    expect(f.text, 'abc -122 def\n');
    expect(f.cursor.c, 7);
  });

  test('decrease next number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc 123 def\n';
    f.createLines(e);
    e.input('\u0018');
    expect(f.text, 'abc 122 def\n');
    expect(f.cursor.c, 6);
  });

  test('decrease negative number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc -123 def\n';
    f.createLines(e);
    e.input('\u0018');
    expect(f.text, 'abc -124 def\n');
    expect(f.cursor.c, 7);
  });

  test('deleteCharNext if cursor is at start of line on second line', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 1);
    e.input('xxxx');
    expect(f.text, 'abc\n\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('don\'t delete newline at end of file (and create extra newline)', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e);
    f.cursor = Position(c: 3, l: 0);
    e.input('xu');
    expect(f.text, 'abc\n');
    expect(f.cursor, Position(c: 3, l: 0));
  });

  test('don\'t crash when deleting newline at end of file', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e);
    f.cursor = Position(c: 3, l: 0);
    e.input('x');
    expect(f.text, 'abc\n');
    expect(f.cursor, Position(c: 3, l: 0));
  });

  test('delete first char', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'a\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('xx');
    expect(f.text, '\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('yank text and paste it at eof should insert newline', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('ye\$p');
    expect(f.text, 'abc\nabc\n');
    expect(f.cursor, Position(c: 3, l: 0));
  });

  test('deleteCharNext at end of file', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    f.cursor = Position(c: 2, l: 1);
    e.input('xxxx');
    expect(f.text, 'abc\nde\n');
    expect(f.cursor, Position(c: 2, l: 1));
  });

  test('delete to eol, move down, repeat and move down', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('Dj.j');
    expect(f.text, '\n\nghi\njkl\n');
    expect(f.cursor, Position(c: 0, l: 2));
  });

  test('go down one line with j', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('j');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('go up one line with k', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 2);
    e.input('k');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('x with count', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n';
    f.createLines(e);
    f.cursor = Position(c: 0, l: 0);
    e.input('3x');
    expect(f.text, 'def\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });
}
