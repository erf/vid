import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/modes.dart';
import 'package:vid/position.dart';

void main() {
  test('defaultInsert', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 0);
    e.input('id\x1b');
    expect(f.text, 'adbc\n');
    expect(f.cursor, Position(c: 1, l: 0));
  });

  test('insertActionEscape', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    e.input('i\x1b');
    expect(f.mode, Mode.normal);
  });

  test('insertActionEnter', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abcdef\n';
    f.createLines();
    f.cursor = Position(c: 3, l: 0);
    e.input('i\n');
    expect(f.text, 'abc\ndef\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('insertActionBackspace', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    e.insert('\x7f');
    expect(f.text, 'abcdef\nghi\n');
    expect(f.cursor, Position(c: 3, l: 0));
  });

  test('insert I should start at first non-empty line', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = '  abc\n';
    f.createLines();
    f.cursor = Position(c: 5, l: 0);
    e.input('I');
    expect(f.cursor, Position(c: 2, l: 0));
  });

  test('insert multiple chars as one insert action', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.createLines();
    e.input('iabc\x1b');
    expect(f.text, 'abc\n');
    expect(f.prevAction!.input, 'abc');
    expect(f.cursor, Position(c: 3, l: 0));
  }, skip: true);
}
