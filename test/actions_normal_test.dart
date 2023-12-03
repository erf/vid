import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/caret.dart';

void main() {
  test('joinLines', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 1);
    e.input('J');
    expect(f.text, 'abc\ndefghi\n');
    expect(f.cursor, Caret(c: 0, l: 1));
  });

  test('actionDeleteLineEnd', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 1, l: 1);
    e.input('D');
    expect(f.text, 'abc\nd\nghi\n');
    expect(f.cursor, Caret(c: 1, l: 1));
  });

  test('actionChangeLineEnd', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'hello world\n';
    f.createLines();
    f.cursor = Caret(c: 5, l: 0);
    e.input('C');
    expect(f.text, 'hello\n');
  });

  test('actionDeleteCharNext', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 1, l: 1);
    e.input('x');
    expect(f.text, 'abc\ndf\nghi\n');
    expect(f.cursor, Caret(c: 1, l: 1));
  });

  test('actionDeleteCharNext delete newline', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Caret(l: 0, c: 3);
    e.input('x');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, Caret(l: 0, c: 3));
  });

  test('actionInsertLineStart', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Caret(c: 2, l: 1);
    e.input('Ix');
    expect(f.text, 'abc\nxdef\n');
    expect(f.cursor, Caret(c: 1, l: 1));
  });

  test('actionAppendLineEnd', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 0);
    e.input('Ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('actionAppendCharNext', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Caret(c: 3, l: 0);
    e.input('ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('cursorLineBottomOrCount G', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 0);
    e.input('G');
    expect(f.cursor, Caret(c: 0, l: 2));
  });

  test('cursorLineBottomOrCount 2G', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 0);
    e.input('2G');
    expect(f.cursor, Caret(c: 0, l: 1));
  });

  test('cursorLineTopOrCount gg', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 2);
    e.input('gg');
    expect(f.cursor, Caret(c: 0, l: 0));
  });

  test('cursorLineTopOrCount 2gg', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 2);
    e.input('2gg');
    expect(f.cursor, Caret(c: 0, l: 1));
  });

  test('repeat dw.', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    e.input('dw.');
    expect(f.text, 'ghi\n');
  });

  test('repeat twice dw..', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    f.createLines();
    e.input('dw..');
    expect(f.text, 'jkl\n');
  });

  test('repeat find fc;;', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc abc abc abc\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 0);
    f.action.findChar = 'c';
    e.input('f;;');
    expect(f.cursor, Caret(c: 10, l: 0));
  });

  test('delete line, move down and paste', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    f.createLines();
    f.cursor = Caret(c: 0, l: 0);
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
    expect(f.cursor, Caret(c: 0, l: 2));
  });
}
