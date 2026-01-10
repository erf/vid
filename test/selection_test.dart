import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/actions/line_edit.dart';
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
      expect(selections[0], Selection(0, 3));
      expect(selections[1], Selection(8, 11));
      expect(selections[2], Selection(16, 19));
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
      expect(selections[0], Selection(1, 2)); // '1'
      expect(selections[1], Selection(3, 4)); // '2'
      expect(selections[2], Selection(5, 6)); // '3'
    });

    test('handles overlapping potential matches', () {
      final text = 'aaaa\n';
      // Non-overlapping matches only
      final selections = selectAllMatches(text, RegExp('aa'));
      expect(selections.length, 2);
      expect(selections[0], Selection(0, 2));
      expect(selections[1], Selection(2, 4));
    });
  });

  group(':sel command', () {
    test('creates selections from regex matches and enters select mode', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';

      LineEdit.select(e, f, ['sel', 'foo']);

      expect(f.selections.length, 2);
      expect(f.selections[0].start, 0);
      expect(f.selections[0].end, 3);
      expect(f.selections[1].start, 8);
      expect(f.selections[1].end, 11);
      expect(f.mode, Mode.select);
    });

    test(':sel world selects full word including last char', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';

      LineEdit.select(e, f, ['sel', 'world']);

      expect(f.selections.length, 1);
      // "world" is at positions 6-10 (inclusive), so end should be 11 (exclusive)
      expect(f.selections[0].start, 6);
      expect(f.selections[0].end, 11);
      // The selected text should be "world"
      expect(
        f.text.substring(f.selections[0].start, f.selections[0].end),
        'world',
      );
      expect(f.mode, Mode.select);
    });

    test('shows message for no matches', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';

      LineEdit.select(e, f, ['sel', 'xyz']);

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

      LineEdit.selectClear(e, f, ['selclear']);

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

    test('cursor setter replaces with single collapsed selection', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.selections = [Selection(5, 10), Selection(15, 20)];

      f.cursor = 25;

      expect(f.selections.length, 1);
      expect(f.selections.first, Selection.collapsed(25));
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

      // Create visual selections for both "foo"s
      f.selections = [Selection(0, 3), Selection(8, 11)];
      f.mode = Mode.select;

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
      // Should stay in select mode
      expect(f.mode, Mode.select);
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
      f.mode = Mode.select;

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
      f.mode = Mode.select;

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

      // Create visual selections for both "AAA"s and enter select mode
      f.selections = [Selection(0, 3), Selection(8, 11)];
      f.mode = Mode.select;

      // Delete
      e.input('d');
      expect(f.text, ' BBB  CCC\n');

      // Undo should restore both
      e.input('u');
      expect(f.text, 'AAA BBB AAA CCC\n');
    });
  });

  group('select mode', () {
    test('escape exits select mode with single cursor', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar foo baz\n';
      f.selections = [Selection(0, 3), Selection(8, 11)];
      f.mode = Mode.select;

      e.input('\x1b'); // Escape

      expect(f.mode, Mode.normal);
      expect(f.selections.length, 1);
      expect(f.selections.first.isCollapsed, true);
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
      f.mode = Mode.select;

      // Move right with 'l'
      e.input('l');

      expect(f.mode, Mode.select); // Still in select mode
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
      f.mode = Mode.select;

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
      f.mode = Mode.select;

      // Primary is first
      expect(f.selections[0].start, 0);

      e.input('\t'); // Tab

      // First selection rotated to end
      expect(f.selections[0].start, 4);
      expect(f.selections[1].start, 8);
      expect(f.selections[2].start, 0);
    });

    test('() cycles through selections', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';
      f.selections = [Selection(0, 3), Selection(4, 7), Selection(8, 11)];
      f.mode = Mode.select;

      e.input(')'); // Next
      expect(f.selections[0].start, 4);

      e.input('('); // Previous
      expect(f.selections[0].start, 0);
    });

    test('x deletes character (like normal mode)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';
      f.selections = [Selection(0, 3), Selection(4, 7)];
      f.mode = Mode.select;

      // x should delete selections (via operator), not remove selection from list
      e.input('x');

      // Both "aaa" and "bbb" deleted, leaving " " + " ccc\n"
      expect(f.text, '  ccc\n');
    });
  });
}
