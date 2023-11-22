import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/modes.dart';
import 'package:vid/position.dart';

void main() {
  test('dd', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('dd');
    expect(f.text, 'def\nghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('dk', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input(
      'dk',
    );
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('dj', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 0);
    e.input('dj');
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });
  test('dd p kP', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('dd');
    expect(f.text, 'abc\nghi\n');
    expect(f.cursor.l, 1);
    expect(f.cursor.c, 0);
    e.input('p');
    expect(f.text, 'abc\nghi\ndef\n');
    expect(f.cursor.l, 2);
    e.input('kP');
    expect(f.text, 'abc\ndef\nghi\ndef\n');
  });

  test('cc', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('cc');
    expect(f.text, 'abc\nghi\n');
    expect(f.cursor.l, 1);
    expect(f.cursor.c, 0);
    expect(f.mode, Mode.insert);
  });

  test('yyP', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    e.input('yy');
    expect(f.yankBuffer, 'def\n');
    e.input('P');
    expect(f.text, 'abc\ndef\ndef\nghi\n');
    expect(f.cursor.l, 1);
    expect(f.cursor.c, 0);
  });

  test('ywP', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\n';
    f.createLines();
    f.cursor = Position(c: 4, l: 0);
    e.input('yw');
    expect(f.yankBuffer, 'def ');
    e.input('P');
    expect(f.text, 'abc def def ghi\n');
  });

  test('ddjp', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    f.createLines();
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
  });

  test('ddjpxp', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    f.createLines();
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
    e.input('xp');
    expect(f.text, '\ndef\nbac\n\nghi\n');
  });
}
