import 'package:test/test.dart';
import 'package:vid/actions_operator.dart';
import 'package:vid/actions_text_objects.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';

void main() {
  test('pendingActionDelete on objectCurrentLine', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('d', redraw: false);
    e.input('d', redraw: false);
    expect(f.text, 'def\nghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('pendingActionDelete on objectLineUp', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('d', redraw: false);
    e.input('k', redraw: false);
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('pendingActionDelete on objectLineDown', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 0);
    e.input('d', redraw: false);
    e.input('j', redraw: false);
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });
}
