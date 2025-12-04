import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_nav.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('move cursor by word 3 times', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi jkl\n';
    f.cursor = 0;
    e.input('3w');
    expect(f.cursor, 12); // 'jkl' starts at offset 12
  });

  test('delete word 3 times', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi jkl\n';
    f.cursor = 0;
    e.input('3dw');
    expect(f.cursor, 0);
    expect(f.text, 'jkl\n');
  });

  test('2dj', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    f.cursor = 0;
    e.input('2dj');
    expect(f.cursor, 0);
    expect(f.text, 'jkl\n');
  });

  test('10w', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi jkl mno pqr stu vwx yz æøå the end\n';
    f.cursor = 0;
    e.input('10w');
    // 10w from start goes: abc->def->ghi->jkl->mno->pqr->stu->vwx->yz->æøå->the
    // 'the' starts at grapheme column 39 (byte offset 41, since æøå is 6 bytes)
    expect(f.columnInLine(f.cursor), 39);
  });

  test('0 (beginning of line)', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi jkl mno pqr stu vwx yz æøå the end\n';
    f.cursor = 41; // somewhere in middle
    e.input('0');
    expect(f.cursor, 0);
  });

  test('3dd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'xxx\nabc yo\ndef\nghi\njkl\n';
    // 'abc yo' line starts at offset 4, 'b' at offset 5
    f.cursor = 5;
    e.input('3dd');
    expect(f.cursor, 4);
    expect(f.text, 'xxx\njkl\n');
  });

  test('3dd with line under longer than above', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'xxx\nabc\ndef ghi\n\ntest\n';
    // 'abc' line starts at offset 4, 'b' at offset 5
    f.cursor = 5;
    e.input('3dd');
    expect(f.cursor, 4);
    expect(f.text, 'xxx\ntest\n');
  });

  test('2dd with cursor at first line at eof', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // Original test: Position(c: 4, l: 0) - column 4 on line 0, clamped to end of 'abc'
    // In byte-offset: this should be cursor at position 2 (last char 'c' of 'abc')
    // or position 3 (the newline), depending on clamping behavior
    f.cursor = 2; // On line 0, 'c' position
    e.input('2dd');
    expect(f.cursor, 0);
    expect(f.text, 'ghi\n');
  });
}
