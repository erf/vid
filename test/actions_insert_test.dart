import 'package:termio/termio.dart';
import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/modes.dart';

void main() {
  test('defaultInsert', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 1; // after 'a'
    e.input('id\x1b');
    expect(f.text, 'adbc\n');
    expect(f.cursor, 1); // cursor stays on 'd'
  });

  test('insertActionEscape', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('i\x1b');
    expect(f.mode, Mode.normal);
  });

  test('insertActionEnter', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abcdef\n';
    f.cursor = 3; // after 'abc'
    e.input('i\n');
    expect(f.text, 'abc\ndef\n');
    expect(f.cursor, 4); // start of 'def' line
  });

  test('insertActionBackspace', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'abc\ndef\nghi\n' - offset 4 is start of 'def' line
    f.cursor = 4;
    e.input('i${Keys.backspace}');
    expect(f.text, 'abcdef\nghi\n');
    expect(f.cursor, 3); // after 'abc'
  });

  test('insert I should start at first non-empty line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = '  abc\n';
    f.cursor = 5; // at 'c'
    e.input('I');
    expect(f.cursor, 2); // at first non-blank 'a'
  });

  test('insert chunk of text', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = '\n';
    f.mode = .insert;
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
    // Verify text contains expected content
    expect(f.text.contains('In the heart of the silent forest,'), true);
    expect(f.text.contains('Nature\'s serenade, timeless and free.'), true);
    // Verify cursor is at end (after all inserted text)
    expect(f.cursor > 0, true);
  });

  test('insert chunk of text in middle of a line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abcd\n';
    f.cursor = 2; // after 'ab'
    e.input('iHI');
    expect(f.text, 'abHIcd\n');
    expect(f.cursor, 4); // after 'abHI'
  });

  test('insert chunk of text in middle of a line already in insert mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.mode = .insert;
    f.text = 'abcd\n';
    f.cursor = 2; // after 'ab'
    e.input('HI');
    expect(f.text, 'abHIcd\n');
    expect(f.cursor, 4); // after 'abHI'
  });

  test('insert backspace at eol should not move back extra char', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 3; // at end of 'abc' before newline
    e.input('i${Keys.backspace}');
    expect(f.text, 'ab\n');
    expect(f.cursor, 2); // after 'ab'
  });

  test('TODO insert multiple chars as one insert action', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    e.input('iabc\x1b');
    expect(f.text, 'abc\n');
    // TODO: When insert repeat is implemented, this should track inserted text
    // expect(f.prevEdit!.insertedText, 'abc');
    expect(f.cursor, 3);
  }, skip: true);

  test('insert in empty file with redraw should not scramble text', () {
    // Regression test: clampCursor was moving cursor off newline even in insert mode,
    // causing text to be inserted at wrong position after draw()
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: true,
    );
    final f = e.file;
    // Start with empty file (just newline)
    expect(f.text, '\n');
    e.input('ihello');
    expect(f.text, 'hello\n');
    expect(f.cursor, 5);
  });

  test('bracketed paste inserts content as single undo operation', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 1;
    f.mode = .insert;

    // Simulate bracketed paste: ESC[200~ content ESC[201~
    e.input('\x1b[200~hello\nworld\x1b[201~');

    expect(f.text, 'ahello\nworldbc\n');
    expect(f.undoList.length, 1); // Single undo entry for entire paste
  });

  test('bracketed paste in normal mode still inserts', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 1;
    // In normal mode

    // Simulate bracketed paste
    e.input('\x1b[200~XYZ\x1b[201~');

    expect(f.text, 'aXYZbc\n');
    expect(f.undoList.length, 1);
  });

  test('bracketed paste single undo reverts entire paste', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 1;
    f.mode = .insert;

    // Paste multiline content
    e.input('\x1b[200~line1\nline2\nline3\x1b[201~');
    expect(f.text, 'aline1\nline2\nline3bc\n');

    // Single undo should revert the entire paste
    e.input('\x1b'); // exit insert mode
    e.input('u'); // undo
    expect(f.text, 'abc\n');
  });

  test('bracketed paste with content before and after markers', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = '\n';
    f.cursor = 0;
    f.mode = .insert;

    // Input with regular chars, paste, then more regular chars
    e.input('A\x1b[200~PASTE\x1b[201~B');

    // A and B are processed as regular insert mode chars (separate undos)
    // PASTE is processed as bracketed paste (single undo)
    expect(f.text, 'APASTEB\n');
  });

  test('bracketed paste split across multiple input calls', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = '\n';
    f.cursor = 0;
    f.mode = .insert;

    // Paste sequence split across multiple input() calls
    e.input('\x1b[200~first');
    e.input(' part');
    e.input(' last\x1b[201~');

    expect(f.text, 'first part last\n');
    expect(f.undoList.length, 1); // Single undo for entire paste
  });
}
