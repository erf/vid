import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/modes.dart';

void main() {
  test('dd', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 0;
    e.input('dd');
    expect(f.text, 'def\nghi\n');
    expect(f.cursor, 0);
  });

  test('dk', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'def' line starts at 4, 'e' at offset 5
    f.cursor = 5;
    e.input('dk');
    expect(f.text, 'ghi\n');
    expect(f.cursor, 0);
  });

  test('dj', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'abc' line, 'b' at offset 1
    f.cursor = 1;
    e.input('dj');
    expect(f.text, 'ghi\n');
    expect(f.cursor, 0);
  });

  test('dd p kP', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'def' line starts at 4, 'e' at offset 5
    f.cursor = 5;
    e.input('dd');
    expect(f.text, 'abc\nghi\n');
    expect(f.lineNumber(f.cursor), 1);
    expect(f.columnInLine(f.cursor), 0);
    e.input('p');
    expect(f.text, 'abc\nghi\ndef\n');
    expect(f.lineNumber(f.cursor), 2);
    e.input('kP');
    expect(f.text, 'abc\ndef\nghi\ndef\n');
  });

  test('cc', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'def' line starts at 4, 'e' at offset 5
    f.cursor = 5;
    e.input('cc');
    expect(f.text, 'abc\nghi\n');
    expect(f.lineNumber(f.cursor), 1);
    expect(f.columnInLine(f.cursor), 0);
    expect(f.mode, Mode.insert);
  });

  test('yyP', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'def' line starts at 4, 'e' at offset 5
    f.cursor = 5;
    e.input('yy');
    expect(e.yankBuffer?.text, 'def\n');
    expect(e.yankBuffer?.linewise, true);
    e.input('P');
    expect(f.text, 'abc\ndef\ndef\nghi\n');
    expect(f.lineNumber(f.cursor), 1);
    expect(f.columnInLine(f.cursor), 0);
  });

  test('ywP', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc def ghi\n';
    // 'def' starts at offset 4
    f.cursor = 4;
    e.input('yw');
    expect(e.yankBuffer?.text, 'def ');
    expect(e.yankBuffer?.linewise, false);
    e.input('P');
    expect(f.text, 'abc def def ghi\n');
  });

  test('ddjp', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
  });

  test('ddjpxp', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n\ndef\n\nghi\n';
    e.input('ddjp');
    expect(f.text, '\ndef\nabc\n\nghi\n');
    e.input('xp');
    expect(f.text, '\ndef\nbac\n\nghi\n');
  });

  test('gu should lowercase', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'ABC\n';
    e.input('gue');
    expect(f.text, 'abc\n');
  });

  test('gU should uppercase', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    e.input('gUe');
    expect(f.text, 'ABC\n');
  });

  test('dd at eof', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'ghi' line starts at offset 8
    f.cursor = 8;
    e.input('dd');
    expect(f.text, 'abc\ndef\n');
  });

  test('dd with space', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n\ndef\nghi\n';
    // empty line at offset 4
    f.cursor = 4;
    e.input('dd');
    expect(f.cursor, 4);
    expect(f.text, 'abc\ndef\nghi\n');
  });

  test('ggdG deletes all content', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 4; // start somewhere in the middle
    e.input('ggdG');
    expect(f.text, '\n', reason: 'Should preserve trailing newline');
    expect(f.cursor, 0);
  });

  test('dd followed by motion should not extend selection', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.cursor = 4; // start of 'def' line
    e.input('dd');
    expect(f.text, 'abc\nghi\n');
    expect(f.mode, Mode.normal);
    // After dd, selection should be collapsed
    expect(f.selections.first.isCollapsed, true);
    // Now move with a motion - selection should stay collapsed
    e.input('w');
    expect(
      f.selections.first.isCollapsed,
      true,
      reason: 'Motion in normal mode should not extend selection',
    );
    expect(f.mode, Mode.normal);
  });

  test('insert then dd then h should not extend selection', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = '\n';
    f.cursor = 0;
    // Type "abc\n" in insert mode
    e.input('iabc\n');
    expect(f.text, 'abc\n\n');
    expect(f.mode, Mode.insert);
    // Escape to normal mode
    e.input('\x1b'); // Escape
    expect(f.mode, Mode.normal);
    expect(
      f.selections.first.isCollapsed,
      true,
      reason: 'Should be collapsed after escape',
    );
    // Delete current line
    e.input('dd');
    expect(
      f.selections.first.isCollapsed,
      true,
      reason: 'Should be collapsed after dd',
    );
    // Move left - this should NOT extend selection
    e.input('h');
    expect(
      f.selections.first.isCollapsed,
      true,
      reason: 'h motion should not extend selection in normal mode',
    );
    e.input('h');
    expect(
      f.selections.first.isCollapsed,
      true,
      reason: 'h motion should not extend selection in normal mode',
    );
    e.input('h');
    expect(
      f.selections.first.isCollapsed,
      true,
      reason: 'h motion should not extend selection in normal mode',
    );
  });

  group('case operators in visual mode', () {
    test('gU converts selection to uppercase', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v'); // Enter visual mode
      e.input('e'); // Select "hello"
      e.input('gU'); // Uppercase

      expect(f.text, 'HELLO world\n');
      expect(f.mode, Mode.normal);
    });

    test('gu converts selection to lowercase', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'HELLO WORLD\n';
      f.cursor = 0;

      e.input('v'); // Enter visual mode
      e.input('e'); // Select "HELLO"
      e.input('gu'); // Lowercase

      expect(f.text, 'hello WORLD\n');
      expect(f.mode, Mode.normal);
    });

    test('gU in visual line mode converts entire lines to uppercase', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello\nworld\nfoo\n';
      f.cursor = 0;

      e.input('V'); // Enter visual line mode
      e.input('j'); // Select 2 lines
      e.input('gU'); // Uppercase

      expect(f.text, 'HELLO\nWORLD\nfoo\n');
      expect(f.mode, Mode.normal);
    });

    test('gu in visual line mode converts entire lines to lowercase', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'HELLO\nWORLD\nFOO\n';
      f.cursor = 0;

      e.input('V'); // Enter visual line mode
      e.input('j'); // Select 2 lines
      e.input('gu'); // Lowercase

      expect(f.text, 'hello\nworld\nFOO\n');
      expect(f.mode, Mode.normal);
    });
  });
}
