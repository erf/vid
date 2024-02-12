import 'package:test/test.dart';
import 'package:vid/actions_command.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';

void main() {
  test('substitute should delete the first occurrence of a pattern', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'hello world';
    f.cursor = Position(l: 0, c: 0);
    CommandActions.substitute(e, f, ['s/l//']);
    expect(f.text, equals('helo world\n'));
  });

  test('substitute should replace the first occurrence of a pattern', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'hello world';
    f.cursor = Position(l: 0, c: 0);
    CommandActions.substitute(e, f, ['s/world/friend/']);
    expect(f.text, equals('hello friend\n'));
  });

  test('substitute should replace multiple occurrences of a pattern', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'this is fun fun fun';
    f.cursor = Position(l: 0, c: 0);
    CommandActions.substitute(e, f, ['s/fun/cool/g']);
    expect(f.text, equals('this is cool cool cool\n'));
  });

  test('search should find the first occurrence of a pattern', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'hello world';
    f.createLines(WrapMode.none, 80, 24);
    f.cursor = Position(l: 0, c: 0);
    e.input('/world\n');
    expect(f.cursor, equals(Position(l: 0, c: 6)));
  });
}
