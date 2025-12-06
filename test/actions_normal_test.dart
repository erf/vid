import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('actionDeleteLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'abc\ndef\nghi\n' - line 1 ('def') starts at offset 4, 'e' is at offset 5
    f.cursor = 5; // at 'e' in 'def'
    e.input('D');
    expect(f.text, 'abc\nd\nghi\n');
    expect(f.cursor, 4); // at 'd'
  });

  test('actionChangeLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = 5; // at space after 'hello'
    e.input('C');
    expect(f.text, 'hello\n');
  });

  test('actionDeleteCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'def' line starts at offset 4, 'e' is at offset 5
    f.cursor = 5;
    e.input('x');
    expect(f.text, 'abc\ndf\nghi\n');
    expect(f.cursor, 5); // stays at same position (now on 'f')
  });

  test('actionDeleteCharNext delete newline', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'abc\n' - newline is at offset 3
    f.cursor = 3;
    e.input('x');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, 3);
  });

  test('actionInsertLineStart', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'def' line starts at offset 4, 'f' is at offset 6
    f.cursor = 6;
    e.input('Ix');
    expect(f.text, 'abc\nxdef\n');
    expect(f.cursor, 5); // after 'x'
  });

  test('actionAppendLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 0;
    e.input('Ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('actionAppendCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'abc' ends at offset 2 ('c'), newline at 3
    f.cursor = 2;
    e.input('ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('cursorLineBottomOrCount G', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 0;
    e.input('G');
    // G goes to last line, which is 'ghi\n' starting at offset 8
    expect(f.lineNumber(f.cursor), 2); // 0-indexed line 2
  });

  test('cursorLineBottomOrCount 2G', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 0;
    e.input('2G');
    // 2G goes to line 2 (1-indexed), which is 'def' at offset 4
    expect(f.lineNumber(f.cursor), 1); // 0-indexed line 1
  });

  test('cursorLineTopOrCount gg', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // Start at 'ghi' line (offset 8)
    f.cursor = 8;
    e.input('gg');
    expect(f.cursor, 0);
  });

  test('cursorLineTopOrCount 2gg', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 8; // 'ghi' line
    e.input('2gg');
    // 2gg goes to line 2 (1-indexed), which is 'def' at offset 4
    expect(f.lineNumber(f.cursor), 1);
  });

  test('repeat dw.', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    e.input('dw.');
    expect(f.text, 'ghi\n');
  });

  test('repeat twice dw..', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    e.input('dw..');
    expect(f.text, 'jkl\n');
  });

  test('repeat find fc;;', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc abc abc abc\n';
    f.cursor = 0;
    f.edit.findStr = 'c';
    e.input('f;;');
    expect(f.cursor, 10); // third 'c'
  });

  test('delete line, move down and paste', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    f.cursor = 0;
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
    // cursor should be on pasted line 'abc'
    expect(f.lineNumber(f.cursor), 2);
  });

  test('joining lines', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 0;
    e.input('J');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, 0);
  });

  test('joining lines with empty line', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n\ndef\n';
    f.cursor = 0;
    e.input('JJ');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, 0);
  });

  test('increase next number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc 123 def\n';
    e.input('\u0001');
    expect(f.text, 'abc 124 def\n');
    expect(f.columnInLine(f.cursor), 6); // at end of number
  });

  test('increase negative number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc -123 def\n';
    e.input('\u0001');
    expect(f.text, 'abc -122 def\n');
    expect(f.columnInLine(f.cursor), 7);
  });

  test('decrease next number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc 123 def\n';
    e.input('\u0018');
    expect(f.text, 'abc 122 def\n');
    expect(f.columnInLine(f.cursor), 6);
  });

  test('decrease negative number', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc -123 def\n';
    e.input('\u0018');
    expect(f.text, 'abc -124 def\n');
    expect(f.columnInLine(f.cursor), 7);
  });

  test('deleteCharNext if cursor is at start of line on second line', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 4; // start of 'def'
    e.input('xxxx');
    expect(f.text, 'abc\n\n');
    expect(f.cursor, 4);
  });

  test('don\'t delete newline at end of file (and create extra newline)', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 2; // at 'c' (last char before newline)
    e.input('xu');
    expect(f.text, 'abc\n');
    expect(f.cursor, 2);
  });

  test('don\'t crash when deleting newline at end of file', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'a\n';
    f.cursor = 0; // at 'a' (only char before newline)
    e.input('xxx'); // delete 'a', then try to delete final newline twice
    expect(f.text, '\n'); // only newline remains, protected
    expect(f.cursor, 0); // cursor at start
  });

  test('delete first char', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'a\n';
    f.cursor = 0;
    e.input('xx');
    expect(f.text, '\n');
    expect(f.cursor, 0);
  });

  test('yank text and paste it at eol', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('ye\$p');
    // ye yanks 'abc' (characterwise), $ goes to 'c', p pastes after cursor
    expect(f.text, 'abcabc\n');
    expect(f.cursor, 5); // cursor at end of pasted text
  });

  test('deleteCharNext at end of file', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'def' starts at offset 4, 'f' is at offset 6
    f.cursor = 6;
    e.input('xxxx');
    // x deletes f, e, d in sequence (cursor moves left after each delete)
    // 4th x does nothing (cursor on empty line, can't move right)
    expect(f.text, 'abc\n\n');
    expect(f.cursor, 4);
  });

  test('delete to eol, move down, repeat and move down', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    f.cursor = 0;
    e.input('Dj.j');
    expect(f.text, '\n\nghi\njkl\n');
    expect(f.lineNumber(f.cursor), 2);
  });

  test('go down one line with j', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 0;
    e.input('j');
    expect(f.lineNumber(f.cursor), 1);
  });

  test('go up one line with k', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 8; // 'ghi' line
    e.input('k');
    expect(f.lineNumber(f.cursor), 1);
  });

  test('x with count', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n';
    f.cursor = 0;
    e.input('3x');
    expect(f.text, 'def\n');
    expect(f.cursor, 0);
  });
}
