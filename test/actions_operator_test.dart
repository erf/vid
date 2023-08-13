import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/modes.dart';
import 'package:vid/position.dart';

void main() {
  test('dd', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('d', redraw: false);
    e.input('d', redraw: false);
    expect(f.text, 'def\nghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('dk', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('d', redraw: false);
    e.input('k', redraw: false);
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('dj', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 0);
    e.input('d', redraw: false);
    e.input('j', redraw: false);
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });
  test('dd p kP', () {
    final e = Editor();
    final f = e.filebuf;
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

  test('cc', () {
    final e = Editor();
    final f = e.filebuf;
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

  test('yyP', () {
    final e = Editor();
    final f = e.filebuf;
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

  test('ywP', () {
    final e = Editor();
    final f = e.filebuf;
    f.text = 'abc def ghi\n';
    f.createLines();
    f.cursor = Position(c: 4, l: 0);
    e.input('y', redraw: false);
    e.input('w', redraw: false);
    expect(f.yankBuffer, 'def ');
    e.input('P', redraw: false);
    expect(f.text, 'abc def def ghi\n');
  });
}
