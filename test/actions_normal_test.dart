import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/modes.dart';
import 'package:vid/selection.dart';

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
    // D deletes from cursor to end of line, preserving the newline
    expect(f.text, 'abc\nd\nghi\n');
    expect(f.cursor, 5); // cursor on newline (deletion start point)
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

  test('toggleCaseUnderCursor ~', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'aB\n';
    f.cursor = 0;

    e.input('~');

    expect(f.text, 'AB\n');
    expect(f.cursor, 1); // moved right to next char
  });

  test('toggleCaseUnderCursor count 2~ clamps at line end', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'aB\n';
    f.cursor = 0;

    e.input('2~');

    expect(f.text, 'Ab\n');
    expect(f.cursor, 2); // cursor can now be at newline position
  });

  test('toggleCaseUnderCursor ~ in visual mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'aBc\n';
    f.cursor = 0;

    e.input('vll~');

    expect(f.text, 'AbC\n');
    expect(f.mode, Mode.normal);
    expect(f.cursor, 0);
  });

  test('toggleCaseUnderCursor ~ in visual line mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'aB\ncD\n';
    f.cursor = 0;

    e.input('V~');

    expect(f.text, 'Ab\ncD\n');
    expect(f.mode, Mode.normal);
    expect(f.cursor, 0);
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

  test('increase with multiple cursors', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'a1 b2 c3\n';
    // Cursor positions: at 'a', 'b', 'c'
    f.selections = [
      Selection.collapsed(0), // before 'a1'
      Selection.collapsed(3), // before 'b2'
      Selection.collapsed(6), // before 'c3'
    ];
    e.input('\u0001'); // Ctrl+A to increase
    expect(f.text, 'a2 b3 c4\n');
    // Cursors should be at end of each number
    expect(f.selections.length, 3);
    expect(f.selections[0].cursor, 1); // after '2'
    expect(f.selections[1].cursor, 4); // after '3'
    expect(f.selections[2].cursor, 7); // after '4'
  });

  test('decrease with multiple cursors and digit changes', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'x10 y100\n';
    f.selections = [
      Selection.collapsed(1), // at '10'
      Selection.collapsed(5), // at '100'
    ];
    e.input('\u0018'); // Ctrl+X to decrease
    expect(f.text, 'x9 y99\n');
    expect(f.selections.length, 2);
    expect(f.selections[0].cursor, 1); // after '9'
    expect(f.selections[1].cursor, 5); // after '99' (shifted due to first edit)
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
    // ye yanks 'abc' (characterwise), $ goes to newline (offset 3), p pastes after = on next line
    expect(f.text, 'abc\nabc');
    expect(f.cursor, 6); // cursor at 'c' of pasted text
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
    // x deletes f (cursor on e), x deletes e (cursor on d), x deletes d (cursor on newline), x deletes newline (joins)
    expect(f.text, 'abc\nde\n');
    expect(f.cursor, 6); // cursor after join
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
    // D at offset 0 deletes 'abc' (preserving newline), j moves down, . repeats D
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

  group('visual paste', () {
    test('p in visual mode replaces selection with yank buffer', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      // Yank 'hello ' then select 'world' and paste
      e.input('yw'); // yank 'hello '
      e.input('w'); // move to 'world'
      e.input('ve'); // select to end of 'world' (visual mode, motion e)
      e.input('p'); // paste

      // 'world' replaced with 'hello '
      expect(f.text, 'hello hello \n');
      expect(f.mode, Mode.normal);
    });

    test('visual paste yanks the replaced text', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc def\n';
      f.cursor = 0;

      // Yank 'abc ' then select 'def' and paste - the replaced 'def' should be yanked
      e.input('yw'); // yank 'abc '
      e.input('w'); // move to 'def'
      e.input('ve'); // select 'def' (v enters visual, e moves to end of word)
      e.input('p'); // paste

      expect(f.text, 'abc abc \n');

      // Yank buffer should now contain 'def' (the replaced text)
      // Note: visual mode is inclusive so it includes 'f' under cursor
      expect(e.yankBuffer?.text, 'def');
    });

    test('P in visual mode also replaces selection', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('yw'); // yank 'hello '
      e.input('w'); // move to 'world'
      e.input('ve'); // select 'world'
      e.input('P'); // paste with P

      expect(f.text, 'hello hello \n');
      expect(f.mode, Mode.normal);
    });

    test('visual line paste replaces entire line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line1\nline2\nline3\n';
      f.cursor = 0;

      e.input('yy'); // yank 'line1\n'
      e.input('j'); // move to line2
      e.input('V'); // enter visual line mode
      e.input('p'); // paste

      expect(f.text, 'line1\nline1\nline3\n');
      expect(f.mode, Mode.normal);
    });

    test('visual paste with collapsed selection in visual mode falls back', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc def\n';
      f.cursor = 0;

      e.input('yw'); // yank 'abc '
      // Force visual mode with a collapsed selection (unusual but possible)
      f.selections = [Selection.collapsed(4)]; // cursor at 'd'
      f.setMode(e, Mode.visual);
      e.input('p'); // paste - should fall back to PasteAfter behavior

      // PasteAfter with character-wise text inserts after cursor ('d' at pos 4)
      // So it inserts 'abc ' after position 4
      expect(f.text, 'abc dabc ef\n');
    });

    test('visual paste replaces word selection', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar baz\n';
      f.cursor = 0;

      e.input('yw'); // yank 'foo '
      e.input('w'); // move to 'bar'
      e.input('ve'); // select 'bar' (v + e motion)
      e.input('p'); // paste

      expect(f.text, 'foo foo  baz\n');
    });

    test('multi-cursor yank and paste distributes pieces correctly', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\nxxx yyy zzz\n';

      // Visual mode selections: anchor to cursor (end is cursor position)
      // Visual mode is inclusive, so Selection(0, 2) yanks chars at 0,1,2 -> 'aaa'
      // The _getOperatorRanges extends end by one grapheme: (0,2) -> (0,3)
      f.selections = [
        Selection(0, 2), // positions 0-2, extended to 0-3 = 'aaa'
        Selection(4, 6), // positions 4-6, extended to 4-7 = 'bbb'
        Selection(8, 10), // positions 8-10, extended to 8-11 = 'ccc'
      ];
      f.setMode(e, Mode.visual);

      // Yank the 3 selections
      e.input('y');
      expect(e.yankBuffer?.pieces.length, 3);
      expect(e.yankBuffer?.pieces[0], 'aaa');
      expect(e.yankBuffer?.pieces[1], 'bbb');
      expect(e.yankBuffer?.pieces[2], 'ccc');

      // Now select 'xxx', 'yyy', 'zzz' on second line (line starts at offset 12)
      f.selections = [
        Selection(12, 14), // 'xxx'
        Selection(16, 18), // 'yyy'
        Selection(20, 22), // 'zzz'
      ];
      f.setMode(e, Mode.visual);

      // Paste - each selection should get its corresponding piece
      e.input('p');

      // Each 3-char word is replaced with its corresponding yanked word
      expect(f.text, 'aaa bbb ccc\naaa bbb ccc\n');
    });

    test(
      'multi-cursor paste with more cursors distributes then falls back',
      () {
        final e = Editor(
          terminal: TestTerminal(width: 80, height: 24),
          redraw: false,
        );
        final f = e.file;
        f.text = 'aa bb\nxx yy zz\n';

        // Yank 2 pieces: 'aa' and 'bb'
        f.selections = [
          Selection(0, 1), // 'aa' (0-1 extended to 0-2)
          Selection(3, 4), // 'bb' (3-4 extended to 3-5)
        ];
        f.setMode(e, Mode.visual);
        e.input('y');
        expect(e.yankBuffer?.pieces.length, 2);
        expect(e.yankBuffer?.pieces[0], 'aa');
        expect(e.yankBuffer?.pieces[1], 'bb');
        expect(e.yankBuffer?.text, 'aabb');

        // Now try to paste to 3 selections - more cursors than pieces
        // First 2 cursors get their pieces, 3rd gets full text
        // Line 2 starts at offset 6
        f.selections = [
          Selection(6, 7), // 'xx' -> gets 'aa'
          Selection(9, 10), // 'yy' -> gets 'bb'
          Selection(12, 13), // 'zz' -> gets 'aabb' (fallback)
        ];
        f.setMode(e, Mode.visual);
        e.input('p');

        // First 2 get pieces, 3rd gets full text
        expect(f.text, 'aa bb\naa bb aabb\n');
      },
    );

    test('multi-cursor paste with fewer cursors uses first N pieces', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aa bb cc\nxx yy\n';

      // Yank 3 pieces
      f.selections = [
        Selection(0, 1), // 'aa'
        Selection(3, 4), // 'bb'
        Selection(6, 7), // 'cc'
      ];
      f.setMode(e, Mode.visual);
      e.input('y');
      expect(e.yankBuffer?.pieces.length, 3);

      // Paste to 2 cursors - should get first 2 pieces
      f.selections = [
        Selection(9, 10), // 'xx' -> gets 'aa'
        Selection(12, 13), // 'yy' -> gets 'bb'
      ];
      f.setMode(e, Mode.visual);
      e.input('p');

      expect(f.text, 'aa bb cc\naa bb\n');
    });
  });
}
