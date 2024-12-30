import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/terminal.dart';

void main() {
  test('no wrap', () {
    final e = Editor(terminal: TestTerminal(12, 12), redraw: false);
    final f = e.file;
    f.text = 'hei jeg heter Erlend 😀😀😀\n';
    f.createLines(e, WrapMode.none);
    expect(f.lines.length, 1);
    expect(f.lines[0].str, 'hei jeg heter Erlend 😀😀😀 ');
  });

  test('no wrap two lines', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(f.lines.length, 2);
    expect(f.lines[0].str, 'abc ');
    expect(f.lines[1].str, 'def ');
  });

  test('no wrap with empty line', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = '\n';
    f.createLines(e, WrapMode.none);
    expect(f.lines.length, 1);
    expect(f.lines[0].str, ' ');
  });

  test('no wrap with newline at end of file', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(f.lines.length, 2);
    expect(f.lines[0].str, 'abc ');
    expect(f.lines[1].str, 'def ');
  });

  test('word wrap simple', () {
    final e = Editor(terminal: TestTerminal(8, 10), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi jkl\n';
    f.createLines(e, WrapMode.word);
    expect(f.lines.length, 2);
    expect(f.lines[0].str, 'abc def ');
    expect(f.lines[1].str, 'ghi jkl ');
  });

  test('word wrap with emoji at end', () {
    final e = Editor(terminal: TestTerminal(8, 20), redraw: false);
    final f = e.file;
    f.text = 'abc def😀 ghi jkl\n';
    f.createLines(e, WrapMode.word);
    expect(f.lines.length, 3);
    expect(f.lines[0].str, 'abc ');
    expect(f.lines[1].str, 'def😀 ');
    expect(f.lines[2].str, 'ghi jkl ');
  });

  test('word wrap check indices', () {
    final e = Editor(terminal: TestTerminal(20, 20), redraw: false);
    final f = e.file;
    f.text = 'The old bookstore exuded\n';
    f.createLines(e, WrapMode.word);
    expect(f.lines.length, 2);
    expect(f.lines[0].str, 'The old bookstore ');
    expect(f.lines[0].start, 0);
    expect(f.lines[0].end, 18);
    expect(f.lines[1].str, 'exuded ');
    expect(f.lines[1].start, 18);
    expect(f.lines[1].end, 25);
  });

  test('word wrap to four lines', () {
    final e = Editor(terminal: TestTerminal(12, 12), redraw: false);
    final f = e.file;
    f.text = 'hei jeg heter Erlend 😀😀😀\n';
    f.createLines(e, WrapMode.word);
    expect(f.lines.length, 4);
    expect(f.lines[0].str, 'hei jeg ');
    expect(f.lines[1].str, 'heter ');
    expect(f.lines[2].str, 'Erlend ');
    expect(f.lines[3].str, '😀😀😀 ');
  });

  test('char wrap to three lines', () {
    final e = Editor(terminal: TestTerminal(12, 12), redraw: false);
    final f = e.file;
    f.text = 'hei jeg heter Erlend 😀😀😀\n';
    f.createLines(e, WrapMode.char);
    expect(f.lines.length, 3);
    expect(f.lines[0].str, 'hei jeg het');
    expect(f.lines[1].str, 'er Erlend ');
    expect(f.lines[2].str, '😀😀😀 ');
  });
}
