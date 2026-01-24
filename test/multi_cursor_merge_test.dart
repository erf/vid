import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/actions/line_edit_actions.dart';
import 'package:vid/editor.dart';
import 'package:vid/modes.dart';

void main() {
  test(
    'dd after :sel should merge cursors when they end up at same position',
    () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello\nhello\ngoodbye\n';

      // Select both "hello" occurrences
      const CmdSelect()(e, f, ['sel', 'hello']);

      expect(f.selections.length, 2);
      expect(f.mode, Mode.visual);

      // Delete the selections with 'd' - deletes the selected text
      e.input('d');

      expect(f.mode, Mode.normal);
      expect(f.text, '\n\ngoodbye\n');
      // After deleting both "hello", we have 2 cursors at start of empty lines
      print('After first d: selections=${f.selections.length}');
      for (var i = 0; i < f.selections.length; i++) {
        print('  Selection $i: ${f.selections[i]}');
      }
      expect(f.selections.length, 2, reason: 'Should have 2 cursors');

      // Now delete the empty lines with dd
      e.input('dd');

      expect(f.mode, Mode.normal);
      expect(f.text, 'goodbye\n');
      print('After dd: selections=${f.selections.length}');
      for (var i = 0; i < f.selections.length; i++) {
        print('  Selection $i: ${f.selections[i]}');
      }
      // Both empty lines deleted, cursors should merge at position 0
      expect(
        f.selections.length,
        1,
        reason: 'Cursors at same position should merge',
      );
    },
  );

  test('dd with visual line selections merges cursors at same position', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello\nhello\ngoodbye\n';

    // Select both "hello" lines
    const CmdSelect()(e, f, ['sel', 'hello']);

    expect(f.selections.length, 2);
    expect(f.mode, Mode.visual);

    // Switch to visual line mode
    e.input('V');
    expect(f.mode, Mode.visualLine);

    // Delete the lines
    e.input('d');

    expect(f.mode, Mode.normal);
    expect(f.text, 'goodbye\n');
    print('After visual line d: selections=${f.selections.length}');
    for (var i = 0; i < f.selections.length; i++) {
      print('  Selection $i: ${f.selections[i]}');
    }
    // Both lines deleted, cursors should be at same position
    expect(
      f.selections.length,
      1,
      reason: 'Cursors at same position should merge',
    );
  });
}
