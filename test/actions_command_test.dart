import 'package:test/test.dart';
import 'package:vid/actions_line_edit.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';
import 'package:vid/terminal.dart';

void main() {
  test('substitute should delete the first occurrence of a pattern', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = Position(l: 0, c: 0);
    LineEdit.substitute(e, f, ['s/l//']);
    expect(f.text, equals('helo world\n'));
  });

  test('substitute should replace the first occurrence of a pattern', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = Position(l: 0, c: 0);
    LineEdit.substitute(e, f, ['s/world/friend/']);
    expect(f.text, equals('hello friend\n'));
  });

  test('substitute should replace multiple occurrences of a pattern', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'this is fun fun fun\n';
    f.cursor = Position(l: 0, c: 0);
    LineEdit.substitute(e, f, ['s/fun/cool/g']);
    expect(f.text, equals('this is cool cool cool\n'));
  });

  test('search should find the first occurrence of a pattern', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello world\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(l: 0, c: 0);
    e.input('/world\n');
    expect(f.cursor, equals(Position(l: 0, c: 6)));
  });
}
