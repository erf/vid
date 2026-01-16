import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/modes.dart';

void main() {
  test('actionDeleteLineEnd', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'abc\ndef\nghi\n' - line 1 ('def') starts at offset 4, 'e' is at offset 5
    f.cursor = 5; // at 'e' in 'def'
    e.input('D');
    expect(f.text, 'abc\nd\nghi\n');
    expect(f.cursor, 4); // at 'd'
  });

  test('actionChangeLineEnd', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = 5; // at space after 'hello'
    e.input('C');
    expect(f.text, 'hello\n');
    expect(f.cursor, 5); // cursor at newline, ready to insert at end of line
  });

  test('actionChangeLineEnd cursor at end of line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 2; // at 'c'
    e.input('C');
    expect(f.text, 'ab\n');
    expect(f.cursor, 2); // cursor at newline, not moved back
  });

  test('actionDeleteCharNext', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'def' line starts at offset 4, 'e' is at offset 5
    f.cursor = 5;
    e.input('x');
    expect(f.text, 'abc\ndf\nghi\n');
    expect(f.cursor, 5); // stays at same position (now on 'f')
  });

  test('actionDeleteCharNext delete newline', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'abc\n' - newline is at offset 3
    f.cursor = 3;
    e.input('x');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, 3);
  });

  test('actionInsertLineStart', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'def' line starts at offset 4, 'f' is at offset 6
    f.cursor = 6;
    e.input('Ix');
    expect(f.text, 'abc\nxdef\n');
    expect(f.cursor, 5); // after 'x'
  });

  test('actionAppendLineEnd', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 0;
    e.input('Ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('actionAppendCharNext', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'abc' ends at offset 2 ('c'), newline at 3
    f.cursor = 2;
    e.input('ax');
    expect(f.text, 'abcx\ndef\n');
  });

  test('cursorLineBottomOrCount G', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 0;
    e.input('G');
    // G goes to last line, which is 'ghi\n' starting at offset 8
    expect(f.lineNumber(f.cursor), 2); // 0-indexed line 2
  });

  test('cursorLineBottomOrCount 2G', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 0;
    e.input('2G');
    // 2G goes to line 2 (1-indexed), which is 'def' at offset 4
    expect(f.lineNumber(f.cursor), 1); // 0-indexed line 1
  });

  test('cursorLineTopOrCount gg', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // Start at 'ghi' line (offset 8)
    f.cursor = 8;
    e.input('gg');
    expect(f.cursor, 0);
  });

  test('cursorLineTopOrCount 2gg', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 8; // 'ghi' line
    e.input('2gg');
    // 2gg goes to line 2 (1-indexed), which is 'def' at offset 4
    expect(f.lineNumber(f.cursor), 1);
  });

  test('repeat dw.', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    e.input('dw.');
    expect(f.text, 'ghi\n');
  });

  test('repeat twice dw..', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    e.input('dw..');
    expect(f.text, 'jkl\n');
  });

  test('repeat find fc;;', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc abc abc abc\n';
    f.cursor = 0;
    f.edit.findStr = 'c';
    e.input('f;;');
    expect(f.cursor, 10); // third 'c'
  });

  test('delete line, move down and paste', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    f.cursor = 0;
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
    // cursor should be on pasted line 'abc'
    expect(f.lineNumber(f.cursor), 2);
  });

  test('joining lines', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 0;
    e.input('J');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, 0);
  });

  test('joining lines with empty line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n\ndef\n';
    f.cursor = 0;
    e.input('JJ');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, 0);
  });

  test('increase next number', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc 123 def\n';
    e.input('\u0001');
    expect(f.text, 'abc 124 def\n');
    expect(f.columnInLine(f.cursor), 6); // at end of number
  });

  test('increase negative number', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc -123 def\n';
    e.input('\u0001');
    expect(f.text, 'abc -122 def\n');
    expect(f.columnInLine(f.cursor), 7);
  });

  test('decrease next number', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc 123 def\n';
    e.input('\u0018');
    expect(f.text, 'abc 122 def\n');
    expect(f.columnInLine(f.cursor), 6);
  });

  test('decrease negative number', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc -123 def\n';
    e.input('\u0018');
    expect(f.text, 'abc -124 def\n');
    expect(f.columnInLine(f.cursor), 7);
  });

  test('deleteCharNext if cursor is at start of line on second line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 4; // start of 'def'
    e.input('xxxx');
    expect(f.text, 'abc\n\n');
    expect(f.cursor, 4);
  });

  test('don\'t delete newline at end of file (and create extra newline)', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 2; // at 'c' (last char before newline)
    e.input('xu');
    expect(f.text, 'abc\n');
    expect(f.cursor, 2);
  });

  test('don\'t crash when deleting newline at end of file', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'a\n';
    f.cursor = 0; // at 'a' (only char before newline)
    e.input('xxx'); // delete 'a', then try to delete final newline twice
    expect(f.text, '\n'); // only newline remains, protected
    expect(f.cursor, 0); // cursor at start
  });

  test('delete first char', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'a\n';
    f.cursor = 0;
    e.input('xx');
    expect(f.text, '\n');
    expect(f.cursor, 0);
  });

  test('yank text and paste it at eol', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('ye\$p');
    // ye yanks 'abc' (characterwise), $ goes to 'c', p pastes after cursor
    expect(f.text, 'abcabc\n');
    expect(f.cursor, 5); // cursor at end of pasted text
  });

  test('deleteCharNext at end of file', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'def' starts at offset 4, 'f' is at offset 6
    f.cursor = 6;
    e.input('xxxx');
    // x deletes f, e, d in sequence (cursor moves left after each delete)
    // 4th x does nothing (cursor on empty line, can't move right)
    expect(f.text, 'abc\n\n');
    expect(f.cursor, 4);
  });

  test('delete to eol, move down, repeat and move down', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\njkl\n';
    f.cursor = 0;
    e.input('Dj.j');
    expect(f.text, '\n\nghi\njkl\n');
    expect(f.lineNumber(f.cursor), 2);
  });

  test('go down one line with j', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 0;
    e.input('j');
    expect(f.lineNumber(f.cursor), 1);
  });

  test('go up one line with k', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 8; // 'ghi' line
    e.input('k');
    expect(f.lineNumber(f.cursor), 1);
  });

  test('x with count', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abcdef\n';
    f.cursor = 0;
    e.input('3x');
    expect(f.text, 'def\n');
    expect(f.cursor, 0);
  });

  test('open line below with o', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 0; // at 'a'
    e.input('ox\x1b');
    expect(f.text, 'abc\nx\ndef\n');
    // cursor should be on 'x' after escape
    expect(f.lineNumber(f.cursor), 1);
  });

  test('open line above with O', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 4; // at 'd' on second line
    e.input('Ox\x1b');
    expect(f.text, 'abc\nx\ndef\n');
    // cursor should be on 'x' (the new line above original 'def')
    expect(f.lineNumber(f.cursor), 1);
  });

  test('open line above with O on first line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 0; // at 'a' on first line
    e.input('Ox\x1b');
    expect(f.text, 'x\nabc\ndef\n');
    // cursor should be on 'x' (the new first line)
    expect(f.lineNumber(f.cursor), 0);
  });

  test('open line above with O places cursor on new empty line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 4; // at 'd' on second line
    e.input('O\x1b');
    expect(f.text, 'abc\n\ndef\n');
    // cursor should be on the new empty line (line 1), not on 'abc' (line 0)
    expect(f.lineNumber(f.cursor), 1);
  });

  group('half-page scrolling', () {
    // Helper to create a buffer with many lines
    String manyLines(int count) =>
        '${List.generate(count, (i) => 'line$i').join('\n')}\n';

    test('Ctrl-D moves cursor and viewport down by half page', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(10); // start at line 10
      f.viewport = 0;

      e.input('\x04'); // Ctrl-D

      // Half page = 24 ~/ 2 = 12 lines
      expect(f.lineNumber(f.cursor), 22); // 10 + 12
      expect(f.lineNumber(f.viewport), 12); // 0 + 12
    });

    test('Ctrl-U moves cursor and viewport up by half page', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(30); // start at line 30
      f.viewport = f.lineOffset(20);

      e.input('\x15'); // Ctrl-U

      // Half page = 24 ~/ 2 = 12 lines
      expect(f.lineNumber(f.cursor), 18); // 30 - 12
      expect(f.lineNumber(f.viewport), 8); // 20 - 12
    });

    test('Ctrl-D clamps cursor at last line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(20);
      f.cursor = f.lineOffset(15); // near end
      f.viewport = f.lineOffset(5);

      e.input('\x04'); // Ctrl-D

      // Cursor should clamp to last line (19)
      expect(f.lineNumber(f.cursor), 19);
    });

    test('Ctrl-U clamps cursor at first line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(5); // near start
      f.viewport = 0;

      e.input('\x15'); // Ctrl-U

      // Cursor should clamp to first line
      expect(f.lineNumber(f.cursor), 0);
    });

    test('Ctrl-D does nothing when cursor on last line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(10);
      f.cursor = f.lineOffset(9); // last line
      final origCursor = f.cursor;

      e.input('\x04'); // Ctrl-D

      expect(f.cursor, origCursor);
    });

    test('Ctrl-U does nothing when cursor on first line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(10);
      f.cursor = 0; // first line

      e.input('\x15'); // Ctrl-U

      expect(f.cursor, 0);
    });

    test('Ctrl-D preserves column position', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      // line10 = 'line10\n', cursor at 'n' (col 2)
      f.cursor = f.lineOffset(10) + 2;
      f.viewport = 0;

      e.input('\x04'); // Ctrl-D

      // Should be at line 22, column 2
      expect(f.lineNumber(f.cursor), 22);
      expect(f.cursor - f.lineOffset(22), 2);
    });

    test('Ctrl-U still moves cursor when viewport already at top', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(20);
      f.viewport = 0; // already at top

      e.input('\x15'); // Ctrl-U

      // Cursor should move up, viewport stays at 0
      expect(f.lineNumber(f.cursor), 8); // 20 - 12
      expect(f.lineNumber(f.viewport), 0);
    });
  });

  group('viewport positioning (zz, zt, zb)', () {
    String manyLines(int count) =>
        List.generate(count, (i) => 'line$i').join('\n') + '\n';

    test('zz centers viewport on cursor line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(50);
      f.viewport = 0;

      e.input('zz');

      // height=24, visible=22 (minus status+command), center offset = 11
      // viewport should be at line 50 - 11 = 39
      expect(f.lineNumber(f.viewport), 39);
      // cursor unchanged
      expect(f.lineNumber(f.cursor), 50);
    });

    test('zt moves current line to top of viewport', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(30);
      f.viewport = 0;

      e.input('zt');

      // viewport should be at cursor line
      expect(f.lineNumber(f.viewport), 30);
      // cursor unchanged
      expect(f.lineNumber(f.cursor), 30);
    });

    test('zb moves current line to bottom of viewport', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(50);
      f.viewport = f.lineOffset(50); // cursor at top initially

      e.input('zb');

      // height=24, visible=22, so viewport = 50 - 22 + 1 = 29
      expect(f.lineNumber(f.viewport), 29);
      // cursor unchanged
      expect(f.lineNumber(f.cursor), 50);
    });

    test('zt at start of file sets viewport to 0', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = 0;
      f.viewport = f.lineOffset(10);

      e.input('zt');

      expect(f.lineNumber(f.viewport), 0);
    });

    test('zb near start clamps viewport to 0', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = manyLines(100);
      f.cursor = f.lineOffset(5); // line 5, less than visible height
      f.viewport = f.lineOffset(10);

      e.input('zb');

      // 5 - 22 + 1 = -16, clamped to 0
      expect(f.lineNumber(f.viewport), 0);
    });
  });

  group('replace mode', () {
    test('r replaces single character and stays in normal mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n';
      f.cursor = 0;

      e.input('rx');

      expect(f.text, 'xbc\n');
      expect(f.cursor, 0); // cursor stays in place for 'r'
      expect(f.mode, Mode.normal); // stays in normal mode
    });

    test('R enters replace mode and replaces continuously until Escape', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcdef\n';
      f.cursor = 0;

      e.input('R');
      expect(f.mode, Mode.replace);

      e.input('xyz');
      expect(f.text, 'xyzdef\n');
      expect(f.cursor, 3);
      expect(f.mode, Mode.replace); // still in replace mode

      e.input('\x1b'); // Escape
      expect(f.mode, Mode.normal);
    });

    test('R replaces characters one at a time', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello\n';
      f.cursor = 1; // at 'e'

      e.input('RXXXX\x1b');

      expect(f.text, 'hXXXX\n');
      // After replacing 4 chars (e,l,l,o), cursor is at position 5 (the newline)
      // Clamped to last char before newline = 4
      expect(f.cursor, 4);
    });

    test('R can extend past end of line by inserting at newline', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'ab\n';
      f.cursor = 0;

      e.input('RXXXX\x1b');

      // Replace a, b, then insert X, X at newline position
      expect(f.text, 'XXXX\n');
      expect(f.cursor, 3);
    });

    test('R inserts when starting at newline', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'ab\ncd\n';
      f.cursor = 2; // at newline after 'ab'

      e.input('RXX\x1b');

      expect(f.text, 'abXX\ncd\n');
      expect(f.cursor, 3);
    });

    test('backspace in replace mode deletes previous character', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcdef\n';
      f.cursor = 0;

      e.input('R');
      e.input('XYZ'); // replace a, b, c with X, Y, Z
      expect(f.text, 'XYZdef\n');
      expect(f.cursor, 3);

      e.input('\x7f'); // backspace
      expect(f.text, 'XYdef\n');
      expect(f.cursor, 2);

      e.input('\x1b'); // Escape
      expect(f.mode, Mode.normal);
    });

    test('backspace at start of file does nothing', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n';
      f.cursor = 0;

      e.input('R');
      e.input('\x7f'); // backspace at position 0

      expect(f.text, 'abc\n');
      expect(f.cursor, 0);
    });
  });
}
