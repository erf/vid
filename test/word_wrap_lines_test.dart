import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_lines.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('no wrap', () {
    final e = Editor(terminal: TestTerminal(12, 12), redraw: false);
    final f = e.file;
    f.text = 'hei jeg heter Erlend 😀😀😀\n';
    e.setWrapMode(.none);
    f.createLines(e);
    expect(f.lines.length, 1);
    expect(f.lines[0].text, 'hei jeg heter Erlend 😀😀😀 ');
  });

  test('no wrap two lines', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(f.lines.length, 2);
    expect(f.lines[0].text, 'abc ');
    expect(f.lines[1].text, 'def ');
  });

  test('no wrap with empty line', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = '\n';
    f.createLines(e);
    expect(f.lines.length, 1);
    expect(f.lines[0].text, ' ');
  });

  test('no wrap with newline at end of file', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(f.lines.length, 2);
    expect(f.lines[0].text, 'abc ');
    expect(f.lines[1].text, 'def ');
  });

  test('word wrap simple', () {
    final e = Editor(terminal: TestTerminal(8, 10), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi jkl\n';
    e.setWrapMode(.word);
    f.createLines(e);
    expect(f.lines.length, 2);
    expect(f.lines[0].text, 'abc def ');
    expect(f.lines[1].text, 'ghi jkl ');
  });

  test('word wrap with emoji at end', () {
    final e = Editor(terminal: TestTerminal(8, 20), redraw: false);
    final f = e.file;
    f.text = 'abc def😀 ghi jkl\n';
    e.setWrapMode(.word);
    f.createLines(e);
    expect(f.lines.length, 3);
    expect(f.lines[0].text, 'abc ');
    expect(f.lines[1].text, 'def😀 ');
    expect(f.lines[2].text, 'ghi jkl ');
  });

  test('word wrap check indices', () {
    final e = Editor(terminal: TestTerminal(20, 20), redraw: false);
    final f = e.file;
    f.text = 'The old bookstore exuded\n';
    e.setWrapMode(.word);
    f.createLines(e);
    expect(f.lines.length, 2);
    expect(f.lines[0].text, 'The old bookstore ');
    expect(f.lines[0].start, 0);
    expect(f.lines[0].end, 18);
    expect(f.lines[1].text, 'exuded ');
    expect(f.lines[1].start, 18);
    expect(f.lines[1].end, 25);
  });

  test('word wrap to four lines', () {
    final e = Editor(terminal: TestTerminal(12, 12), redraw: false);
    final f = e.file;
    f.text = 'hei jeg heter Erlend 😀😀😀\n';
    e.setWrapMode(.word);
    f.createLines(e);
    expect(f.lines.length, 4);
    expect(f.lines[0].text, 'hei jeg ');
    expect(f.lines[1].text, 'heter ');
    expect(f.lines[2].text, 'Erlend ');
    expect(f.lines[3].text, '😀😀😀 ');
  });

  test('char wrap to three lines', () {
    final e = Editor(terminal: TestTerminal(12, 12), redraw: false);
    final f = e.file;
    f.text = 'hei jeg heter Erlend 😀😀😀\n';
    e.setWrapMode(.char);
    f.createLines(e);
    expect(f.lines.length, 3);
    expect(f.lines[0].text, 'hei jeg het');
    expect(f.lines[1].text, 'er Erlend ');
    expect(f.lines[2].text, '😀😀😀 ');
  });
}
