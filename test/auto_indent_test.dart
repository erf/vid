import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';

void main() {
  group('Auto-Indent', () {
    test('preserves space indentation on enter', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '  line1\n';
      f.cursor = 7; // end of line1
      e.input('i\n');
      expect(f.text, '  line1\n  \n');
      expect(f.cursor, 10); // after the 2 spaces on the new line
    });

    test('preserves tab indentation on enter', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '\t\tline1\n';
      f.cursor = 7; // end of line1
      e.input('i\n');
      expect(f.text, '\t\tline1\n\t\t\n');
      expect(f.cursor, 10); // after the 2 tabs on the new line
    });

    test('preserves mixed indentation on enter', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = ' \t line1\n';
      f.cursor = 8; // end of line1
      e.input('i\n');
      expect(f.text, ' \t line1\n \t \n');
      expect(f.cursor, 12); // after ' \t ' on the new line
    });

    test('only indents up to cursor position when splitting line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '    line1\n';
      f.cursor = 2; // in the middle of the 4 spaces
      e.input('i\n');
      // It should insert \n + 2 spaces. The remaining 2 spaces of the original line move to the next line.
      expect(f.text, '  \n    line1\n');
      expect(
        f.cursor,
        5,
      ); // after the 2 spaces on the new line (2 spaces + \n + 2 spaces)
    });

    test('openLineBelow (o) preserves indentation', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '  line1\n';
      f.cursor = 2; // on 'l'
      e.input('o');
      expect(f.text, '  line1\n  \n');
      expect(f.cursor, 10); // after the 2 spaces on the new line
    });

    test('openLineAbove (O) preserves indentation', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '  line1\n';
      f.cursor = 2; // on 'l'
      e.input('O');
      expect(f.text, '  \n  line1\n');
      expect(f.cursor, 2); // after the 2 spaces on the new line
    });

    test('respects autoIndent = false', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      e.config = e.config.copyWith(autoIndent: false);
      final f = e.file;
      f.text = '  line1\n';
      f.cursor = 7; // end of line1
      e.input('i\n');
      expect(f.text, '  line1\n\n');
      expect(f.cursor, 8); // start of new line, no indent
    });

    test('indents further after block starter {', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'if (true) {\n';
      f.cursor = 11; // end of line
      e.input('i\n');
      expect(f.text, 'if (true) {\n    \n');
      expect(f.cursor, 16); // 11 + 1 (\n) + 4 (spaces)
    });

    test('indents further after block starter [', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '  var list = [\n';
      f.cursor = 14; // end of line
      e.input('i\n');
      // Existing indent is 2. Step is detected as 2. New indent should be 4.
      expect(f.text, '  var list = [\n    \n');
      expect(f.cursor, 19); // 14 + 1 + 4
    });

    test('o command indents further after block starter', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'void main() {\n';
      f.cursor = 5; // on 'm'
      e.input('o');
      expect(f.text, 'void main() {\n    \n');
      expect(f.cursor, 18);
    });

    test('detects 2-space indentation step even if tabWidth is 4', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      e.config = e.config.copyWith(tabWidth: 4);
      final f = e.file;
      f.text = '  if (true) {\n';
      f.cursor = 13; // end of line
      e.input('i\n');
      // Existing indent is 2. It should add 2 more (total 4), not 4 more (total 6).
      expect(f.text, '  if (true) {\n    \n');
      expect(f.cursor, 18);
    });

    test('detects indentation step from previous lines', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      e.config = e.config.copyWith(tabWidth: 4);
      final f = e.file;
      f.text = '  line 1\n    if (true) {\n';
      f.cursor = 24; // end of line 2
      e.input('i\n');
      // Line 1 has 2 spaces, Line 2 has 4 spaces. Step is 2.
      // New line should have 4 + 2 = 6 spaces.
      expect(f.text, '  line 1\n    if (true) {\n      \n');
      expect(f.cursor, 31);
    });

    test('indents with multiple tabs after block starter', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '\t\tif (true) {\n';
      f.cursor = 13; // end of line
      e.input('i\n');
      // Existing indent is 2 tabs. Should add 1 more tab (total 3).
      expect(f.text, '\t\tif (true) {\n\t\t\t\n');
      expect(f.cursor, 17); // 13 + 1 (\n) + 3 (tabs)
    });

    test('o command with multiple tabs indents correctly', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '\t\t\tvoid nested() {\n';
      f.cursor = 5; // somewhere on the line
      e.input('o');
      // Existing indent is 3 tabs. Should add 1 more (total 4).
      expect(f.text, '\t\t\tvoid nested() {\n\t\t\t\t\n');
      expect(f.cursor, 23); // 18 + 1 (\n) + 4 tabs
    });
  });
}
