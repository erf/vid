import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/action/file_actions.dart';
import 'package:vid/action/paste_actions.dart';
import 'package:vid/action/line_edit_input_actions.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/modes.dart';
import 'package:vid/yank_buffer.dart';

void main() {
  group('Paste action', () {
    test('Paste(.after) inserts characterwise text after cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n';
      f.cursor = 0; // on 'a'
      e.yankBuffer = YankBuffer(['XY'], linewise: false);
      const Paste(PasteWhere.after)(e, f);
      // Characterwise paste after 'a' → 'aXYbc'
      expect(f.text, 'aXYbc\n');
    });

    test('Paste(.before) inserts characterwise text at cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n';
      f.cursor = 0;
      e.yankBuffer = YankBuffer(['XY'], linewise: false);
      const Paste(PasteWhere.before)(e, f);
      expect(f.text, 'XYabc\n');
    });

    test('Paste(.after) linewise inserts on next line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\n';
      f.cursor = 0;
      e.yankBuffer = YankBuffer(['XX\n'], linewise: true);
      const Paste(PasteWhere.after)(e, f);
      expect(f.text, 'abc\nXX\ndef\n');
    });

    test('Paste(.before) linewise inserts on previous line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\n';
      f.cursor = 4; // on 'd'
      e.yankBuffer = YankBuffer(['XX\n'], linewise: true);
      const Paste(PasteWhere.before)(e, f);
      expect(f.text, 'abc\nXX\ndef\n');
    });

    test('Paste with no yank buffer is a no-op', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n';
      e.yankBuffer = null;
      const Paste(PasteWhere.after)(e, f);
      expect(f.text, 'abc\n');
    });
  });

  group('Quit action', () {
    test(
      'Quit() with unsaved buffer shows error message and does not quit',
      () {
        final e = Editor(
          terminal: TestTerminal(width: 80, height: 24),
          redraw: false,
        );
        final f = e.file;
        f.text = 'abc\n';
        f.replaceAt(0, 'X', config: e.config); // mark modified
        expect(f.modified, isTrue);

        // Calling Quit() (default check mode) should NOT exit; it shows error.
        // We can't actually call e.quit() in tests (calls exit()), so just
        // verify it doesn't throw and the message is set.
        const Quit()(e, f);
        expect(e.message, isNotNull);
        expect(e.message!.text, contains('unsaved'));
      },
    );
  });

  group('LineEditExecuteSearch', () {
    test('SearchDir.forward sets searchNext motion', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo bar\n';
      f.cursor = 0;
      f.setMode(e, Mode.search);
      f.input.lineEdit = 'bar';
      const LineEditExecuteSearch(SearchDir.forward)(e, f);
      expect(f.cursor, 4); // first 'bar'
      expect(f.mode, Mode.normal);
    });

    test('SearchDir.backward sets searchPrev motion', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo bar\n';
      f.cursor = 14; // last char
      f.setMode(e, Mode.searchBackward);
      f.input.lineEdit = 'foo';
      const LineEditExecuteSearch(SearchDir.backward)(e, f);
      // From offset 14, prev 'foo' is at offset 8
      expect(f.cursor, 8);
      expect(f.mode, Mode.normal);
    });
  });
}
