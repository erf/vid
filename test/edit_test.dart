import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('make sure action is reset on wrong key in normal mode', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('Æ');
    expect(f.edit.cmdKey, '');
    expect(f.cursor, 0);
    expect(f.text, 'abc\n');
  });

  test('make sure action is reset on wrong key in operator mode', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('dÆ');
    expect(f.edit.cmdKey, '');
    expect(f.cursor, 0);
    expect(f.text, 'abc\n');
  });

  test('make sure prev action is correct in normal mode', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('dw');
    expect(f.text, '\n');
    expect(f.edit.cmdKey, '');
    expect(f.prevEdit!.cmdKey, '');
  });

  test('make sure prev motion is correct in normal mode', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('w');
    expect(f.edit.cmdKey, '');
  });
}
