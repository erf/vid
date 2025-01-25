import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/keys.dart';
import 'package:vid/modes.dart';
import 'package:vid/position.dart';
import 'package:vid/terminal_dummy.dart';

void main() {
  test('defaultInsert', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 1, l: 0);
    e.input('id\x1b');
    expect(f.text, 'adbc\n');
    expect(f.cursor, Position(c: 1, l: 0));
  });

  test('insertActionEscape', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 0);
    e.input('i\x1b');
    expect(f.mode, Mode.normal);
  });

  test('insertActionEnter', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 3, l: 0);
    e.input('i\n');
    expect(f.text, 'abc\ndef\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('insertActionBackspace', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 1);
    e.input('i${Keys.backspace}');
    expect(f.text, 'abcdef\nghi\n');
    expect(f.cursor, Position(c: 3, l: 0));
  });

  test('insert I should start at first non-empty line', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = '  abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 5, l: 0);
    e.input('I');
    expect(f.cursor, Position(c: 2, l: 0));
  });

  test('insert chunk of text', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = '\n';
    f.createLines(e, WrapMode.none);
    f.mode = Mode.insert;
    // insert longer text with multiple lines
    const longTextWithMultipleLines = """
In the heart of the silent forest,
Whispers of ancient trees stir the air.
Leaves rustle with secrets untold,
Dancing in the sun's gentle glare.

A lone stream murmurs a soft melody,
Winding through the emerald embrace.
Nature's serenade, timeless and free.

""";
    e.input(longTextWithMultipleLines);
    expect(f.lines[0].str, 'In the heart of the silent forest, ');
    expect(f.lines[7].str, 'Nature\'s serenade, timeless and free. ');
    expect(f.lines.length, 10);
    expect(f.cursor, Position(c: 0, l: 9));
  });

  test('insert chunk of text in middle of a line', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcd\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 2, l: 0);
    e.input('iHI');
    expect(f.text, 'abHIcd\n');
    expect(f.cursor, Position(c: 4, l: 0));
  });

  test('insert chunk of text in middle of a line already in insert mode', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.mode = Mode.insert;
    f.text = 'abcd\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 2, l: 0);
    e.input('HI');
    expect(f.text, 'abHIcd\n');
    expect(f.cursor, Position(c: 4, l: 0));
  });

  test('insert backspace at eol should not move back extra char', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 3, l: 0);
    e.input('i${Keys.backspace}');
    expect(f.text, 'ab\n');
    expect(f.cursor, Position(c: 2, l: 0));
  });

  test('TODO insert multiple chars as one insert action', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.createLines(e, WrapMode.none);
    e.input('iabc\x1b');
    expect(f.text, 'abc\n');
    expect(f.prevEdit!.cmdKey, 'abc');
    expect(f.cursor, Position(c: 3, l: 0));
  }, skip: true);
}
