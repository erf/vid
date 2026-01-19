import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/actions/line_edit_actions.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/modes.dart';
import 'package:vid/selection.dart';

void main() {
  group('Selection', () {
    test('collapsed selection has equal anchor and cursor', () {
      final sel = Selection.collapsed(5);
      expect(sel.anchor, 5);
      expect(sel.cursor, 5);
      expect(sel.isCollapsed, true);
      expect(sel.start, 5);
      expect(sel.end, 5);
      expect(sel.length, 0);
    });

    test('forward selection (anchor < cursor)', () {
      final sel = Selection(5, 10);
      expect(sel.anchor, 5);
      expect(sel.cursor, 10);
      expect(sel.isCollapsed, false);
      expect(sel.start, 5);
      expect(sel.end, 10);
      expect(sel.length, 5);
    });

    test('backward selection (anchor > cursor)', () {
      final sel = Selection(10, 5);
      expect(sel.anchor, 10);
      expect(sel.cursor, 5);
      expect(sel.isCollapsed, false);
      expect(sel.start, 5);
      expect(sel.end, 10);
      expect(sel.length, 5);
    });

    test('withCursor creates new selection', () {
      final sel = Selection(5, 10);
      final newSel = sel.withCursor(15);
      expect(newSel.anchor, 5);
      expect(newSel.cursor, 15);
    });

    test('collapse creates collapsed at cursor', () {
      final sel = Selection(5, 10);
      final collapsed = sel.collapse();
      expect(collapsed.anchor, 10);
      expect(collapsed.cursor, 10);
    });

    test('collapseToStart creates collapsed at start', () {
      final sel = Selection(10, 5);
      final collapsed = sel.collapseToStart();
      expect(collapsed.anchor, 5);
      expect(collapsed.cursor, 5);
    });

    test('collapseToEnd creates collapsed at end', () {
      final sel = Selection(10, 5);
      final collapsed = sel.collapseToEnd();
      expect(collapsed.anchor, 10);
      expect(collapsed.cursor, 10);
    });

    test('equality', () {
      expect(Selection(5, 10), Selection(5, 10));
      expect(Selection(5, 10), isNot(Selection(10, 5)));
      expect(Selection.collapsed(5), Selection(5, 5));
    });
  });

  group('selectAllMatches', () {
    test('finds all matches', () {
      final text = 'foo bar foo baz foo\n';
      final selections = selectAllMatches(text, RegExp('foo'));
      expect(selections.length, 3);
      // Cursor-based: cursor on last char of match (end - 1)
      expect(selections[0], Selection(0, 2));
      expect(selections[1], Selection(8, 10));
      expect(selections[2], Selection(16, 18));
    });

    test('returns empty list for no matches', () {
      final text = 'hello world\n';
      final selections = selectAllMatches(text, RegExp('xyz'));
      expect(selections, isEmpty);
    });

    test('handles regex with groups', () {
      final text = 'a1b2c3\n';
      final selections = selectAllMatches(text, RegExp(r'\d'));
      expect(selections.length, 3);
      // Single char matches: cursor on same char (collapsed-like but still a selection)
      expect(selections[0], Selection(1, 1)); // '1' - single char at position 1
      expect(selections[1], Selection(3, 3)); // '2' - single char at position 3
      expect(selections[2], Selection(5, 5)); // '3' - single char at position 5
    });

    test('handles overlapping potential matches', () {
      final text = 'aaaa\n';
      // Non-overlapping matches only
      final selections = selectAllMatches(text, RegExp('aa'));
      expect(selections.length, 2);
      // Cursor-based: cursor on last char of match
      expect(selections[0], Selection(0, 1));
      expect(selections[1], Selection(2, 3));
    });
  });

  group('mergeSelections', () {
    test('returns empty list for empty input', () {
      expect(mergeSelections([]), isEmpty);
    });

    test('returns single selection unchanged', () {
      final result = mergeSelections([Selection(5, 10)]);
      expect(result.length, 1);
      expect(result[0], Selection(5, 10));
    });

    test('merges overlapping selections', () {
      final result = mergeSelections([Selection(0, 10), Selection(5, 15)]);
      expect(result.length, 1);
      expect(result[0], Selection(0, 15));
    });

    test('merges adjacent selections', () {
      final result = mergeSelections([Selection(0, 5), Selection(5, 10)]);
      expect(result.length, 1);
      expect(result[0], Selection(0, 10));
    });

    test('does not merge non-overlapping selections', () {
      final result = mergeSelections([Selection(0, 5), Selection(10, 15)]);
      expect(result.length, 2);
      expect(result[0], Selection(0, 5));
      expect(result[1], Selection(10, 15));
    });

    test('handles unsorted input', () {
      final result = mergeSelections([
        Selection(10, 15),
        Selection(0, 5),
        Selection(3, 12),
      ]);
      expect(result.length, 1);
      expect(result[0], Selection(0, 15));
    });

    test('merges multiple groups correctly', () {
      final result = mergeSelections([
        Selection(0, 5),
        Selection(3, 8),
        Selection(20, 25),
        Selection(22, 30),
      ]);
      expect(result.length, 2);
      expect(result[0], Selection(0, 8));
      expect(result[1], Selection(20, 30));
    });
  });

  group(':sel command', () {
    test('creates selections from regex matches and enters visual mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';

      const CmdSelect()(e, f, ['sel', 'foo']);

      expect(f.selections.length, 2);
      // Cursor-based: cursor on last char of match
      expect(f.selections[0].start, 0);
      expect(f.selections[0].end, 2); // cursor on 'o' at position 2
      expect(f.selections[1].start, 8);
      expect(f.selections[1].end, 10); // cursor on 'o' at position 10
      expect(f.mode, Mode.visual);
    });

    test(':sel world selects full word including last char', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';

      const CmdSelect()(e, f, ['sel', 'world']);

      expect(f.selections.length, 1);
      // "world" at positions 6-10, cursor on last char 'd' at position 10
      expect(f.selections[0].start, 6);
      expect(f.selections[0].end, 10); // cursor on 'd'
      // The selected text (with extension) should be "world"
      // In cursor-based model, need to add 1 to get the full range
      expect(
        f.text.substring(f.selections[0].start, f.selections[0].end + 1),
        'world',
      );
      expect(f.mode, Mode.visual);
    });

    test('shows message for no matches', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';

      const CmdSelect()(e, f, ['sel', 'xyz']);

      // Should keep single selection
      expect(f.selections.length, 1);
    });

    test(':selclear clears multiple selections', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo foo foo\n';

      // Create multiple selections
      f.selections = [Selection(0, 3), Selection(4, 7), Selection(8, 11)];
      expect(f.selections.length, 3);

      const CmdSelectClear()(e, f, ['selclear']);

      expect(f.selections.length, 1);
      expect(f.selections.first.isCollapsed, true);
    });
  });

  group('FileBuffer.cursor compatibility', () {
    test('cursor getter returns first selection cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.selections = [Selection(5, 10), Selection(15, 20)];

      expect(f.cursor, 10); // cursor of first selection
    });

    test('cursor setter updates first selection only', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.selections = [Selection(5, 10), Selection(15, 20)];

      f.cursor = 25;

      // Only first selection is updated; second remains
      expect(f.selections.length, 2);
      expect(f.selections.first, Selection(5, 25)); // cursor moved to 25
      expect(f.selections[1], Selection(15, 20)); // unchanged
    });
  });

  group('operators on visual selections', () {
    test('d deletes all visual selections and keeps collapsed cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';

      // Create visual selections for both "foo"s (cursor-based: cursor on last char)
      f.selections = [Selection(0, 2), Selection(8, 10)];
      f.mode = Mode.visual;

      // Press 'd' to delete
      e.input('d');

      // Both "foo"s should be deleted
      expect(f.text, ' bar  baz\n');
      // Should have two collapsed selections at adjusted positions
      expect(f.selections.length, 2);
      expect(f.selections[0], Selection.collapsed(0)); // First "foo" was at 0
      expect(
        f.selections[1],
        Selection.collapsed(5),
      ); // Second "foo" was at 8, now 8-3=5
      // Returns to normal mode (preserving multi-cursors)
      expect(f.mode, Mode.normal);
    });

    test('d keeps all collapsed cursors at adjusted positions', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\nhello world\nhello world\nhello world\n';

      // Select all "wor" matches
      f.selections = selectAllMatches(f.text, RegExp('wor'));
      expect(f.selections.length, 4);
      f.mode = Mode.visual;

      // Delete with 'd'
      e.input('d');

      // Text should have "wor" removed from each line
      expect(f.text, 'hello ld\nhello ld\nhello ld\nhello ld\n');

      // Should have 4 collapsed selections at adjusted positions
      expect(f.selections.length, 4);
      // Each line is now 9 chars: "hello ld\n"
      // Original positions were 6, 18, 30, 42
      // After deletions: 6, 18-3=15, 30-6=24, 42-9=33
      // But line length is now 9, so: 6, 6+9=15, 6+18=24, 6+27=33
      expect(f.selections[0], Selection.collapsed(6));
      expect(f.selections[1], Selection.collapsed(15));
      expect(f.selections[2], Selection.collapsed(24));
      expect(f.selections[3], Selection.collapsed(33));
    });

    test('d cursors correct even when selections reordered', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\nhello world\nhello world\nhello world\n';

      // Select all "wor" matches
      f.selections = selectAllMatches(f.text, RegExp('wor'));
      f.mode = Mode.visual;

      // Simulate cycling selections (Tab rotates to end)
      f.selections = [
        f.selections[1],
        f.selections[2],
        f.selections[3],
        f.selections[0],
      ];

      // Delete with 'd'
      e.input('d');

      // Selections should be in document order with correct positions
      expect(f.text, 'hello ld\nhello ld\nhello ld\nhello ld\n');
      expect(f.selections.length, 4);
      expect(f.selections[0], Selection.collapsed(6));
      expect(f.selections[1], Selection.collapsed(15));
      expect(f.selections[2], Selection.collapsed(24));
      expect(f.selections[3], Selection.collapsed(33));
    });

    test('c changes all visual selections', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'old one old two old three\n';

      // Create visual selections for all "old"s
      f.selections = [Selection(0, 3), Selection(8, 11), Selection(16, 19)];

      // Press 'c' to change
      e.input('c');

      // All "old"s should be deleted, cursor at first
      expect(f.text, ' one  two  three\n');
      // Should be in insert mode
      expect(f.mode, Mode.insert);
    });

    test('y yanks all visual selections', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';

      // Create visual selections
      f.selections = [Selection(0, 3), Selection(8, 11)];

      // Press 'y' to yank
      e.input('y');

      // Text should be unchanged
      expect(f.text, 'aaa bbb ccc\n');
      // Yank buffer should have concatenated selections
      expect(e.yankBuffer?.text, 'aaaccc');
    });

    test('d without visual selection enters operator pending', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      // Only collapsed selection
      expect(f.hasVisualSelection, false);

      // Press 'd' - should enter operator pending, not delete
      e.input('d');
      expect(f.mode, Mode.operatorPending);
      expect(f.text, 'hello world\n'); // unchanged
    });

    test('delete all selections undoes as single operation', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'AAA BBB AAA CCC\n';

      // Create visual selections for both "AAA"s (cursor-based: cursor on last char)
      f.selections = [Selection(0, 2), Selection(8, 10)];
      f.mode = Mode.visual;

      // Delete
      e.input('d');
      expect(f.text, ' BBB  CCC\n');

      // Undo should restore both
      e.input('u');
      expect(f.text, 'AAA BBB AAA CCC\n');
    });
  });

  group('visual mode multi-selection', () {
    test('escape exits visual mode with multiple collapsed cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';
      f.selections = [Selection(0, 3), Selection(8, 11)];
      f.mode = Mode.visual;

      e.input('\x1b'); // Escape

      expect(f.mode, Mode.normal);
      // Now keeps multiple cursors (collapsed selections)
      expect(f.selections.length, 2);
      expect(f.selections[0].isCollapsed, true);
      expect(f.selections[0].cursor, 3); // collapsed at cursor position
      expect(f.selections[1].isCollapsed, true);
      expect(f.selections[1].cursor, 11); // collapsed at cursor position
    });

    test('motions move all selection cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';
      // Create selections at start of each "foo"
      f.selections = [Selection.collapsed(0), Selection.collapsed(8)];
      f.mode = Mode.visual;

      // Move right with 'l'
      e.input('l');

      expect(f.mode, Mode.visual); // Still in visual mode
      expect(f.selections.length, 2);
      expect(f.selections[0].cursor, 1);
      expect(f.selections[1].cursor, 9);
    });

    test('motions extend visual selections', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';
      // Create visual selections for "foo"
      f.selections = [Selection(0, 3), Selection(8, 11)];
      f.mode = Mode.visual;

      // Move right with 'l' - extends selection
      e.input('l');

      expect(f.selections.length, 2);
      // Anchors stay, cursors move
      expect(f.selections[0].anchor, 0);
      expect(f.selections[0].cursor, 4);
      expect(f.selections[1].anchor, 8);
      expect(f.selections[1].cursor, 12);
    });

    test('tab cycles to next selection', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';
      f.selections = [Selection(0, 3), Selection(4, 7), Selection(8, 11)];
      f.mode = Mode.visual;

      // Primary is first
      expect(f.selections[0].start, 0);

      e.input('\t'); // Tab

      // First selection rotated to end
      expect(f.selections[0].start, 4);
      expect(f.selections[1].start, 8);
      expect(f.selections[2].start, 0);
    });

    test('Shift+Tab cycles to previous selection', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';
      f.selections = [Selection(0, 3), Selection(4, 7), Selection(8, 11)];
      f.mode = Mode.visual;

      e.input('\t'); // Tab - next
      expect(f.selections[0].start, 4);

      e.input('\x1b[Z'); // Shift+Tab - previous
      expect(f.selections[0].start, 0);
    });

    test('x deletes character (like normal mode)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';
      // Cursor-based: "aaa" is 0-2, "bbb" is 4-6
      f.selections = [Selection(0, 2), Selection(4, 6)];
      f.mode = Mode.visual;

      // x should delete selections (via operator), not remove selection from list
      e.input('x');

      // Both "aaa" and "bbb" deleted, leaving " " + " ccc\n"
      expect(f.text, '  ccc\n');
    });
  });

  group('visual mode', () {
    test('v enters visual mode with collapsed selection at cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 3;

      e.input('v');

      expect(f.mode, Mode.visual);
      expect(f.selections.length, 1);
      expect(f.selections[0].anchor, 3);
      expect(f.selections[0].cursor, 3);
      expect(f.selections[0].isCollapsed, true);
    });

    test('motion extends selection in visual mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v'); // Enter visual mode
      e.input('w'); // Move word forward

      expect(f.mode, Mode.visual);
      expect(f.selections.length, 1);
      expect(f.selections[0].anchor, 0); // Anchor stays at start
      expect(f.selections[0].start, 0);
      expect(f.selections[0].end, 6); // "hello " selected
    });

    test('escape exits visual mode and returns to normal', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('w');
      e.input('\x1b'); // Escape

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 1);
      expect(f.selections[0].isCollapsed, true);
    });

    test('o swaps anchor and cursor in visual mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('w'); // Selection is anchor=0, cursor=6

      expect(f.selections[0].anchor, 0);
      expect(f.selections[0].cursor, 6);

      e.input('o'); // Swap

      expect(f.selections[0].anchor, 6);
      expect(f.selections[0].cursor, 0);
      // Range should be the same
      expect(f.selections[0].start, 0);
      expect(f.selections[0].end, 6);
    });

    test('d deletes visual selection and returns to normal mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('e'); // Select "hello" (e is inclusive, moves to 'o')
      e.input('d'); // Delete

      expect(f.text, ' world\n');
      expect(f.mode, Mode.normal);
    });

    test('c changes visual selection and enters insert mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('e'); // Select "hello"
      e.input('c'); // Change

      expect(f.text, ' world\n');
      expect(f.mode, Mode.insert);
    });

    test('y yanks visual selection and returns to normal mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('e'); // Select "hello"
      e.input('y'); // Yank

      expect(f.text, 'hello world\n'); // Text unchanged
      expect(f.mode, Mode.normal);
      expect(e.yankBuffer?.text, 'hello');
    });

    test('backward motion extends selection backward', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 6; // At 'w'

      e.input('v');
      e.input('b'); // Move word backward

      expect(f.selections[0].anchor, 6);
      expect(f.selections[0].cursor, 0);
      expect(f.selections[0].start, 0);
      expect(f.selections[0].end, 6);
    });

    test('e motion includes end character', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('e'); // Move to end of word (inclusive)

      // 'e' moves cursor to 'o' (position 4). In visual mode, selection stores
      // the raw cursor position. Extension happens when operating.
      expect(f.selections[0].anchor, 0);
      expect(f.selections[0].cursor, 4);

      // When we delete, it should include the character at cursor (the 'o')
      e.input('d');
      expect(f.text, ' world\n'); // "hello" deleted
    });

    test('count works with motions in visual mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'one two three\n';
      f.cursor = 0;

      e.input('v');
      e.input('2w'); // Move 2 words forward

      expect(f.selections[0].anchor, 0);
      expect(f.selections[0].start, 0);
      // "one two " = 8 chars
      expect(f.selections[0].end, 8);
    });

    test('x deletes inclusive of cursor character', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('llll'); // Move to 'o' in "hello" (position 4)

      expect(f.selections[0].anchor, 0);
      expect(f.selections[0].cursor, 4);

      e.input('x'); // Delete - should include 'o'

      // "hello" (positions 0-4 inclusive) should be deleted
      expect(f.text, ' world\n');
      expect(f.cursor, 0); // Cursor should be at start of deleted region
      expect(f.mode, Mode.normal);
    });

    test('d with l motion deletes inclusive of cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('llll'); // Move to 'o' (position 4)
      e.input('d'); // Delete

      expect(f.text, ' world\n');
      expect(f.cursor, 0);
    });

    test('y yanks inclusive of cursor character', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 0;

      e.input('v');
      e.input('llll'); // Move to 'o' (position 4)
      e.input('y'); // Yank

      expect(f.text, 'hello world\n'); // Text unchanged
      expect(e.yankBuffer?.text, 'hello'); // Includes 'o'
    });
  });

  group('visual line mode', () {
    test('V enters visual line mode with collapsed selection', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 5; // Middle of first line

      e.input('V');

      expect(f.mode, Mode.visualLine);
      expect(f.selections.length, 1);
      // Selection is collapsed at cursor, line expansion happens at render/operator time
      expect(f.selections[0].isCollapsed, true);
      expect(f.selections[0].cursor, 5);
    });

    test('V enters visual line mode preserving multiple cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';

      // Multi-cursor (collapsed selections) across multiple lines.
      f.selections = [
        Selection.collapsed(0),
        Selection.collapsed(9),
        Selection.collapsed(18),
      ];

      e.input('V');

      expect(f.mode, Mode.visualLine);
      expect(f.selections.length, 3);
      expect(f.selections.every((s) => s.isCollapsed), true);
      expect(f.selections[0].cursor, 0);
      expect(f.selections[1].cursor, 9);
      expect(f.selections[2].cursor, 18);
    });

    test('j motion moves cursor to next line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V');
      e.input('j'); // Move down one line

      expect(f.mode, Mode.visualLine);
      // Anchor stays on line 0, cursor moves to line 1
      // Selection range spans anchor line (0) to cursor line (1)
      expect(f.lineNumber(f.selections[0].anchor), 0);
      expect(f.lineNumber(f.selections[0].cursor), 1);
    });

    test('k motion shrinks selection when moving back', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V');
      e.input('j'); // Move to line 1
      e.input('k'); // Move back to line 0

      expect(f.mode, Mode.visualLine);
      // Both anchor and cursor should be on line 0
      expect(f.lineNumber(f.selections[0].anchor), 0);
      expect(f.lineNumber(f.selections[0].cursor), 0);
    });

    test('escape exits visual line mode preserving cursor position', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\n';
      f.cursor = 5;

      e.input('V');
      e.input('\x1b'); // Escape

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 1);
      expect(f.selections[0].isCollapsed, true);
      expect(f.cursor, 5); // Cursor stays at original position
    });

    test('escape from backward visual line selection preserves cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 19; // 'line three'

      e.input('V');
      e.input('k'); // Move cursor up to line two (backward selection)
      e.input('\x1b'); // Escape

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 1);
      expect(f.selections[0].isCollapsed, true);
      // Cursor should be on line two where we moved it, not at the start
      expect(f.lineNumber(f.cursor), 1); // Line two (0-indexed)
    });

    test('d deletes entire lines in visual line mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V');
      e.input('j'); // Select 2 lines
      e.input('d'); // Delete

      expect(f.text, 'line three\n');
      expect(f.mode, Mode.normal);
    });

    test('y yanks entire lines with linewise flag', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V');
      e.input('j'); // Select 2 lines
      e.input('y'); // Yank

      expect(f.text, 'line one\nline two\nline three\n'); // Unchanged
      expect(f.mode, Mode.normal);
      expect(e.yankBuffer?.text, 'line one\nline two\n');
      expect(e.yankBuffer?.linewise, true);
    });

    test('d on single line deletes that line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V');
      e.input('d'); // Delete first line

      expect(f.text, 'line two\nline three\n');
      expect(f.mode, Mode.normal);
      expect(f.cursor, 0);
    });

    test('G motion extends selection to last line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V');
      e.input('G'); // Go to last line

      expect(f.mode, Mode.visualLine);
      // Anchor on line 0, cursor on last line
      expect(f.lineNumber(f.selections[0].anchor), 0);
      expect(f.lineNumber(f.selections[0].cursor), 2);
    });

    test('o swaps anchor and cursor direction', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V');
      e.input('j'); // Select 2 lines

      final anchorBefore = f.selections[0].anchor;
      final cursorBefore = f.selections[0].cursor;

      e.input('o'); // Swap

      expect(f.selections[0].anchor, cursorBefore);
      expect(f.selections[0].cursor, anchorBefore);
    });

    test('pasting after linewise yank pastes on next line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V'); // Select first line
      e.input('y'); // Yank it

      f.cursor = 18; // Go to third line
      e.input('p'); // Paste after

      expect(f.text, 'line one\nline two\nline three\nline one\n');
    });
  });

  group('multi-cursor mode', () {
    test('escape from visual mode creates multiple collapsed cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';
      // Create selections at "foo" matches
      f.selections = [Selection(0, 3), Selection(8, 11)];
      f.mode = Mode.visual;

      e.input('\x1b'); // Escape

      // Should now be in multi-cursor mode (normal with multiple collapsed selections)
      expect(f.mode, Mode.normal);
      expect(f.hasMultipleCursors, true);
      expect(f.selections.length, 2);
      expect(f.selections[0], Selection.collapsed(3));
      expect(f.selections[1], Selection.collapsed(11));
    });

    test('motions in multi-cursor mode move all cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcdef\nabcdef\n';
      // Set up two collapsed cursors
      f.selections = [Selection.collapsed(0), Selection.collapsed(7)];

      // Move right (w - word motion)
      e.input('l');

      expect(f.hasMultipleCursors, true);
      expect(f.selections.length, 2);
      expect(f.selections[0].cursor, 1);
      expect(f.selections[1].cursor, 8);
    });

    test('insert mode with multiple cursors inserts at all positions', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\nabc\n';
      // Set up two collapsed cursors at start of each line
      f.selections = [Selection.collapsed(0), Selection.collapsed(4)];

      // Enter insert mode and type
      e.input('i');
      e.input('X');

      expect(f.text, 'Xabc\nXabc\n');
      // Cursors should be after the inserted char
      expect(f.selections[0].cursor, 1);
      expect(
        f.selections[1].cursor,
        6,
      ); // +1 for 'X' at first cursor, +1 for own 'X'
    });

    test('escape in normal mode with multiple cursors collapses to single', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';
      f.selections = [Selection.collapsed(0), Selection.collapsed(8)];

      e.input('\x1b'); // Escape

      expect(f.selections.length, 1);
      expect(f.selections.first, Selection.collapsed(0));
    });

    test('delete operator with multiple cursors deletes at all positions', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcXdef\nabcXdef\n';
      // Cursors at 'X' positions
      f.selections = [Selection.collapsed(3), Selection.collapsed(11)];

      e.input('dl'); // Delete char under cursor

      expect(f.text, 'abcdef\nabcdef\n');
      // Cursors should remain at same positions (relative)
      expect(f.selections.length, 2);
    });

    test(
      'change operator with multiple cursors enters insert at all positions',
      () {
        final e = Editor(
          terminal: TestTerminal(width: 80, height: 24),
          redraw: false,
        );
        final f = e.file;
        f.text = 'foo bar\nfoo bar\n';
        // Cursors at start of "foo"
        f.selections = [Selection.collapsed(0), Selection.collapsed(8)];

        e.input('cw'); // Change word (deletes to start of next word)
        expect(f.mode, Mode.insert);

        e.input('baz '); // Insert "baz " to replace "foo "

        expect(f.text, 'baz bar\nbaz bar\n');
      },
    );

    test('backspace in multi-cursor insert mode deletes at all positions', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'ab\nab\n';
      // Cursors after 'a'
      f.selections = [Selection.collapsed(1), Selection.collapsed(4)];
      f.mode = Mode.insert;

      e.input('\x7f'); // Backspace

      expect(f.text, 'b\nb\n');
    });

    test('hasMultipleCursors returns true only for multiple collapsed', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'test\n';

      // Single collapsed - not multi-cursor
      f.selections = [Selection.collapsed(0)];
      expect(f.hasMultipleCursors, false);

      // Multiple collapsed - is multi-cursor
      f.selections = [Selection.collapsed(0), Selection.collapsed(2)];
      expect(f.hasMultipleCursors, true);

      // Multiple but one non-collapsed - not multi-cursor (visual selection)
      f.selections = [Selection(0, 2), Selection.collapsed(3)];
      expect(f.hasMultipleCursors, false);
    });

    test('collapseToPrimaryCursor reduces to single cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'test\n';
      f.selections = [Selection.collapsed(2), Selection.collapsed(4)];

      f.collapseToPrimaryCursor();

      expect(f.selections.length, 1);
      expect(f.selections.first, Selection.collapsed(2));
    });

    test('collapseSelections collapses all selections', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'test text\n';
      f.selections = [Selection(0, 4), Selection(5, 9)];

      f.collapseSelections();

      expect(f.selections.length, 2);
      expect(f.selections[0], Selection.collapsed(4));
      expect(f.selections[1], Selection.collapsed(9));
    });

    test('A (append at end of line) works with multiple cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\nhello world\nhello world\n';
      // Cursors at 'w' in each "world" (positions 6, 18, 30)
      f.selections = [
        Selection.collapsed(6),
        Selection.collapsed(18),
        Selection.collapsed(30),
      ];

      e.input('A'); // A is aliased to $a - go to end of line and append
      e.input('!');

      expect(f.text, 'hello world!\nhello world!\nhello world!\n');
    });

    test('a (append after cursor) works with multiple cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\nabc\nabc\n';
      // Cursors at 'b' (positions 1, 5, 9)
      f.selections = [
        Selection.collapsed(1),
        Selection.collapsed(5),
        Selection.collapsed(9),
      ];

      e.input('a'); // Append after cursor
      e.input('X');

      expect(f.text, 'abXc\nabXc\nabXc\n');
    });

    test('o (open line below) works with multiple cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
        config: const Config(autoIndent: false),
      );
      final f = e.file;
      f.text = 'line1\nline2\nline3\n';
      // Cursors on each line
      f.selections = [
        Selection.collapsed(0),
        Selection.collapsed(6),
        Selection.collapsed(12),
      ];

      e.input('o'); // Open line below
      e.input('new');

      expect(f.text, 'line1\nnew\nline2\nnew\nline3\nnew\n');
    });

    test('O (open line above) works with multiple cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
        config: const Config(autoIndent: false),
      );
      final f = e.file;
      f.text = 'line1\nline2\nline3\n';
      // Cursors on each line
      f.selections = [
        Selection.collapsed(0),
        Selection.collapsed(6),
        Selection.collapsed(12),
      ];

      e.input('O'); // Open line above
      e.input('new');

      expect(f.text, 'new\nline1\nnew\nline2\nnew\nline3\n');
    });
  });

  group('visual to visual line mode transition', () {
    test('V from visual mode expands selection to full lines', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('v'); // Enter visual mode
      expect(f.mode, Mode.visual);
      expect(f.selections[0].isCollapsed, true);

      e.input('j'); // Move to next line
      e.input('j'); // Move to third line

      // Now we have a selection spanning from line 0 to line 2
      expect(f.selections[0].isCollapsed, false);

      e.input('V'); // Switch to visual line mode

      expect(f.mode, Mode.visualLine);
      // Selection should expand to full lines for highlighting, but cursor stays at current position
      final sel = f.selections[0];
      expect(f.lineNumber(sel.start), 0); // Anchor at first line
      expect(sel.start, 0); // Start of first line
      // Cursor (end) stays at current position, not moved to line end
      // Line expansion for operators/rendering happens dynamically
      expect(sel.cursor, 18); // Cursor stayed at position 18 (start of line 3)
    });

    test('V from visual mode preserves multiple selections', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';

      // Two visual selections on different lines. One forward, one backward.
      f.selections = [Selection(0, 2), Selection(16, 9)];
      f.mode = Mode.visual;

      e.input('V');

      expect(f.mode, Mode.visualLine);
      expect(f.selections.length, 2);

      // Cursors stay where they were.
      expect(f.selections[0].cursor, 2);
      expect(f.selections[1].cursor, 9);

      // Anchors are normalized to the relevant line boundary.
      expect(f.selections[0].anchor, 0); // start of line 1
      expect(f.selections[1].anchor, 17); // end of line 2 (newline offset)
    });
  });

  group('visual line mode I - insert at line starts', () {
    test('I in visual line mode creates cursors at start of each line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 0;

      e.input('V'); // Enter visual line mode
      expect(f.mode, Mode.visualLine);

      e.input('j'); // Extend to second line
      e.input('j'); // Extend to third line

      e.input('I'); // Press I to create cursors at line starts

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 3);
      // Main cursor stays at current cursor position (line 3)
      expect(
        f.selections[0].cursor,
        18,
      ); // Start of line 3 (current cursor line)
      expect(f.selections[1].cursor, 0); // Start of line 1
      expect(f.selections[2].cursor, 9); // Start of line 2
      // All should be collapsed
      expect(f.selections.every((s) => s.isCollapsed), true);
    });

    test('I in visual line mode with backward selection', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'line one\nline two\nline three\n';
      f.cursor = 18; // Start at third line

      e.input('V'); // Enter visual line mode
      e.input('k'); // Move up to second line
      e.input('k'); // Move up to first line

      e.input('I'); // Press I

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 3);
      // Main cursor stays at current cursor position (line 1)
      expect(
        f.selections[0].cursor,
        0,
      ); // Start of line 1 (current cursor line)
      expect(f.selections[1].cursor, 9); // Start of line 2
      expect(f.selections[2].cursor, 18); // Start of line 3
    });
  });

  group('add cursor above/below', () {
    test('Ctrl+J adds cursor on line below', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\nghi\n';
      f.cursor = 1; // On 'b' (column 1)

      e.input('\n'); // Ctrl+J (\x0a)

      expect(f.selections.length, 2);
      expect(
        f.selections[0].cursor,
        5,
      ); // New cursor on 'e' (column 1 of line 2) - main cursor
      expect(f.selections[1].cursor, 1); // Original cursor on 'b'
    });

    test('Ctrl+K adds cursor on line above', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\nghi\n';
      f.cursor = 5; // On 'e' (column 1 of line 2)

      e.input('\x0b'); // Ctrl+K

      expect(f.selections.length, 2);
      expect(
        f.selections[0].cursor,
        1,
      ); // New cursor on 'b' (column 1 of line 1)
      expect(f.selections[1].cursor, 5); // Original cursor on 'e'
    });

    test('Ctrl+J multiple times adds multiple cursors', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\nghi\njkl\n';
      f.cursor = 0;

      e.input('\n'); // Add cursor on line 2
      e.input('\n'); // Add cursor on line 3
      e.input('\n'); // Add cursor on line 4

      expect(f.selections.length, 4);
      expect(f.selections[0].cursor, 12); // Line 4 - main cursor (newest)
      // Previous main cursors follow, then rest sorted by position
      expect(f.selections[1].cursor, 8); // Line 3
      expect(f.selections[2].cursor, 0); // Line 1 (original)
      expect(f.selections[3].cursor, 4); // Line 2
    });

    test('Ctrl+J keeps visual column with short line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcdef\nxy\nqrstuv\n';
      f.cursor = 4; // On 'e' (column 4)

      e.input('\n'); // Add cursor on short line

      expect(f.selections.length, 2);
      // Short line only has 2 chars, so cursor should be at end (column 1)
      expect(
        f.selections[0].cursor,
        8,
      ); // On 'y' (last char of line 2) - main cursor
      expect(f.selections[1].cursor, 4); // Original on 'e'
    });

    test('Ctrl+J does nothing at last line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\n';
      f.cursor = 4; // On last line

      e.input('\n'); // Try to add cursor below

      expect(f.selections.length, 1); // No new cursor
      expect(f.selections[0].cursor, 4);
    });

    test('Ctrl+K does nothing at first line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\n';
      f.cursor = 1; // On first line

      e.input('\x0b'); // Try to add cursor above

      expect(f.selections.length, 1); // No new cursor
      expect(f.selections[0].cursor, 1);
    });
  });

  group('selectWordUnderCursor', () {
    test('selects word under cursor and enters visual mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';
      f.cursor = 6; // On 'w' of 'world'

      e.input('\x0e'); // Ctrl+N

      expect(f.mode, Mode.visual);
      expect(f.selections.length, 1);
      // 'world' is at bytes 6-10, cursor on last char 'd' at 10
      expect(f.selections[0].anchor, 6);
      expect(f.selections[0].cursor, 10);
    });

    test('selects word when cursor is in middle of word', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'testing\n';
      f.cursor = 3; // On 't' in 'testing'

      e.input('\x0e'); // Ctrl+N

      expect(f.mode, Mode.visual);
      // 'testing' is at bytes 0-6
      expect(f.selections[0].anchor, 0);
      expect(f.selections[0].cursor, 6);
    });

    test('selects whitespace if cursor is on whitespace', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello   world\n';
      f.cursor = 6; // On first space

      e.input('\x0e'); // Ctrl+N

      expect(f.mode, Mode.visual);
      // Whitespace '   ' is at bytes 5-7
      expect(f.selections[0].anchor, 5);
      expect(f.selections[0].cursor, 7);
    });
  });

  group('selectAllMatchesOfSelection', () {
    test('selects all matches of current selection in visual mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz foo\n';
      f.cursor = 0;

      // First select 'foo' manually
      e.input('v'); // Enter visual mode
      e.input('ll'); // Select 'foo' (cursor on last 'o')
      expect(f.mode, Mode.visual);
      expect(
        f.text.substring(f.selections[0].start, f.selections[0].end + 1),
        'foo',
      );

      e.input('\x01'); // Ctrl+A to select all matches

      expect(f.mode, Mode.visual);
      expect(f.selections.length, 3);
      // All 'foo' occurrences
      expect(f.selections[0], Selection(0, 2));
      expect(f.selections[1], Selection(8, 10));
      expect(f.selections[2], Selection(16, 18));
    });

    test('selects word under cursor first if selection is collapsed', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz foo\n';
      f.cursor = 0; // On 'f' of first 'foo'

      e.input('v'); // Enter visual mode (collapsed selection)
      e.input('\x01'); // Ctrl+A

      expect(f.mode, Mode.visual);
      expect(f.selections.length, 3);
      // All 'foo' occurrences
      expect(f.selections[0], Selection(0, 2));
      expect(f.selections[1], Selection(8, 10));
      expect(f.selections[2], Selection(16, 18));
    });
  });

  group('visualLineInsertAtLineEnds', () {
    test('creates cursors at end of each selected line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndefgh\nij\n';
      f.cursor = 0;

      // Select all three lines
      e.input('V'); // Enter visual line mode
      e.input('jj'); // Select to third line
      e.input('A'); // Create cursors at line ends

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 3);
      // Cursor positions should be at end of each line (before newline)
      // Line 0: 'abc' -> cursor on 'c' at offset 2
      // Line 1: 'defgh' -> cursor on 'h' at offset 8
      // Line 2: 'ij' -> cursor on 'j' at offset 11
      // Main cursor should be on line 2 (where cursor ended up)
      expect(f.selections[0].cursor, 11); // Main cursor on 'j' (line 2)
      expect(f.selections[1].cursor, 2); // On 'c' (line 0)
      expect(f.selections[2].cursor, 8); // On 'h' (line 1)
    });

    test('handles empty lines', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n\nxyz\n';
      f.cursor = 0;

      e.input('V'); // Enter visual line mode
      e.input('jj'); // Select all three lines
      e.input('A'); // Create cursors at line ends

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 3);
      // Line 0: 'abc' -> cursor on 'c' at offset 2
      // Line 1: '' (empty) -> cursor at line start (offset 4)
      // Line 2: 'xyz' -> cursor on 'z' at offset 7
      expect(f.selections[0].cursor, 7); // Main cursor on 'z' (line 2)
      expect(f.selections[1].cursor, 2); // On 'c' (line 0)
      expect(f.selections[2].cursor, 4); // Empty line - at line start
    });
  });

  group('selection cycling in normal mode', () {
    test('Tab cycles to next selection in normal mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\nghi\n';
      f.cursor = 0;

      // Create multiple cursors
      e.input('\n'); // Add cursor below
      e.input('\n'); // Add cursor below again

      expect(f.selections.length, 3);
      // After AddCursorBelow x2: primary is at line 2 (bottom), others at lines 0, 1
      // Sorted by document position: line0, line1, line2
      // Primary (line2) is last in document order

      e.input(
        '\t',
      ); // Tab to cycle - goes to next in document order (wraps to first)

      // Primary should now be at line 0 (first in document order)
      expect(f.selections[0].cursor, 0); // line 0
    });

    test('[s and ]s cycle selections in normal mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\nghi\n';
      f.cursor = 0;

      // Create multiple cursors at lines 0, 1, 2
      e.input('\n'); // Add cursor below
      e.input('\n'); // Add cursor below again

      expect(f.selections.length, 3);
      // Primary is at line 2 (position 8), which is last in document order

      e.input(']s'); // Next selection - wraps to first in document order

      // Primary should now be at line 0 (first in document)
      expect(f.selections[0].cursor, 0);

      e.input('[s'); // Previous selection - wraps to last in document order

      // Primary should now be at line 2 (last in document)
      expect(f.selections[0].cursor, 8);
    });
  });
}
