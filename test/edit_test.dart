import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';
import 'package:vid/terminal.dart';

void main() {
  test('make sure action is reset on wrong key in normal mode', () {
    final e = Editor(term: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 0);
    e.input('Æ');
    expect(f.editOp.input, '');
    expect(f.editOp.opInput, '');
    expect(f.cursor, Position(c: 0, l: 0));
    expect(f.text, 'abc\n');
  });

  test('make sure action is reset on wrong key in operator mode', () {
    final e = Editor(term: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 0);
    e.input('dÆ');
    expect(f.editOp.input, '');
    expect(f.editOp.opInput, '');
    expect(f.cursor, Position(c: 0, l: 0));
    expect(f.text, 'abc\n');
  });

  test('make sure prev action is correct in normal mode', () {
    final e = Editor(term: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 0);
    e.input('dw');
    expect(f.text, '\n');
    expect(f.editOp.input, '');
    expect(f.editOp.opInput, '');
    expect(f.prevEditOp!.input, 'd');
    expect(f.prevEditOp!.opInput, 'w');
  });

  test('make sure prev motion is correct in normal mode', () {
    final e = Editor(term: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 0);
    e.input('w');
    expect(f.editOp.input, '');
    expect(f.editOp.opInput, '');
  });
}
