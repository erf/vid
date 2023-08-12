import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/modes.dart';
import 'package:vid/position.dart';

void main() {
  test('operatorActionDelete', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('d', redraw: false);
    e.input('d', redraw: false);
    expect(f.text, 'abc\nghi\n');
    expect(f.cursor.l, 1);
    expect(f.cursor.c, 0);
    e.input('p', redraw: false);
    expect(f.text, 'abc\nghi\ndef\n');
    expect(f.cursor.l, 2);
    e.input('k', redraw: false);
    e.input('P', redraw: false);
    expect(f.text, 'abc\ndef\nghi\ndef\n');
  });

  test('operatorActionChange', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('c', redraw: false);
    e.input('c', redraw: false);
    expect(f.text, 'abc\nghi\n');
    expect(f.cursor.l, 1);
    expect(f.cursor.c, 0);
    expect(f.mode, Mode.insert);
  });

  test('operatorActionYank', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('y', redraw: false);
    e.input('y', redraw: false);
    expect(f.yankBuffer, 'def\n');
    e.input('P', redraw: false);
    expect(f.text, 'abc\ndef\ndef\nghi\n');
    expect(f.cursor.l, 1);
    expect(f.cursor.c, 0);
  });
}
