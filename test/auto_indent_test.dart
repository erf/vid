import 'package:termio/termio.dart';
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
  });
}
