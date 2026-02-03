import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';

void main() {
  group('TextEdit', () {
    test('basic constructor', () {
      final edit = TextEdit(0, 5, 'hello');
      expect(edit.start, 0);
      expect(edit.end, 5);
      expect(edit.newText, 'hello');
    });

    test('insert constructor', () {
      final edit = TextEdit.insert(10, 'world');
      expect(edit.start, 10);
      expect(edit.end, 10);
      expect(edit.newText, 'world');
    });

    test('delete constructor', () {
      final edit = TextEdit.delete(5, 10);
      expect(edit.start, 5);
      expect(edit.end, 10);
      expect(edit.newText, '');
    });
  });

  group('applyEdits', () {
    test('single edit', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';

      applyEdits(f, [TextEdit(0, 5, 'hi')], e.config);

      expect(f.text, 'hi world\n');
      expect(f.undoList.length, 1);
      expect(f.undoList.last.ops.length, 1);
    });

    test('multiple edits in same buffer', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';
      //        0123456789...

      // Replace 'aaa' with 'XXX' and 'ccc' with 'ZZZ'
      applyEdits(f, [TextEdit(0, 3, 'XXX'), TextEdit(8, 11, 'ZZZ')], e.config);

      expect(f.text, 'XXX bbb ZZZ\n');
      expect(f.undoList.length, 1);
      expect(f.undoList.last.ops.length, 2);
    });

    test('multiple edits applied in reverse order preserves positions', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar baz\n';
      //        012345678901

      // Replace with different length strings
      // 'foo' (0-3) -> 'XXXXX' (5 chars)
      // 'bar' (4-7) -> 'Y' (1 char)
      // 'baz' (8-11) -> 'ZZ' (2 chars)
      applyEdits(f, [
        TextEdit(0, 3, 'XXXXX'),
        TextEdit(4, 7, 'Y'),
        TextEdit(8, 11, 'ZZ'),
      ], e.config);

      expect(f.text, 'XXXXX Y ZZ\n');
    });

    test('insertions only', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'ac\n';

      // Insert 'b' between 'a' and 'c'
      applyEdits(f, [TextEdit.insert(1, 'b')], e.config);

      expect(f.text, 'abc\n');
    });

    test('deletions only', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcdef\n';

      // Delete 'bc' (1-3) and 'ef' (4-6)
      applyEdits(f, [TextEdit.delete(1, 3), TextEdit.delete(4, 6)], e.config);

      expect(f.text, 'ad\n');
    });

    test('empty edit list does nothing', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'unchanged\n';

      final result = applyEdits(f, [], e.config);

      expect(f.text, 'unchanged\n');
      expect(result, isEmpty);
      expect(f.undoList, isEmpty);
    });

    test('adjacent edits (non-overlapping)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aabbcc\n';

      // Replace 'aa' and 'bb' (adjacent)
      applyEdits(f, [TextEdit(0, 2, 'XX'), TextEdit(2, 4, 'YY')], e.config);

      expect(f.text, 'XXYYcc\n');
    });

    test('overlapping edits are merged', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcdef\n';

      // Overlapping: (0-3) and (2-5) both include offset 2
      // Should merge to (0-5) with combined text 'XY'
      applyEdits(f, [TextEdit(0, 3, 'X'), TextEdit(2, 5, 'Y')], e.config);

      // 'abcdef' -> delete 0-5 ('abcde'), insert 'XY' -> 'XYf\n'
      expect(f.text, 'XYf\n');
    });

    test('overlapping deletions are merged', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abcdefghij\n';

      // Overlapping deletions: (2-5) and (4-8) overlap at 4-5
      applyEdits(f, [TextEdit.delete(2, 5), TextEdit.delete(4, 8)], e.config);

      // Should merge to delete (2-8), leaving 'abij\n'
      expect(f.text, 'abij\n');
    });
  });

  group('undo with applyEdits', () {
    test('undo reverses all edits', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'aaa bbb ccc\n';
      f.cursor = 0;

      applyEdits(f, [TextEdit(0, 3, 'XXX'), TextEdit(8, 11, 'ZZZ')], e.config);

      expect(f.text, 'XXX bbb ZZZ\n');

      f.undo();

      expect(f.text, 'aaa bbb ccc\n');
      expect(f.cursor, 0);
      expect(f.undoList, isEmpty);
      expect(f.redoList.length, 1);
    });

    test('undo with no history returns null', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'test\n';

      final result = f.undo();

      expect(result, isNull);
    });

    test('multiple undo operations', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'original\n';

      // First batch
      applyEdits(f, [TextEdit(0, 8, 'first')], e.config);
      expect(f.text, 'first\n');

      // Second batch
      applyEdits(f, [TextEdit(0, 5, 'second')], e.config);
      expect(f.text, 'second\n');

      // Undo second
      f.undo();
      expect(f.text, 'first\n');

      // Undo first
      f.undo();
      expect(f.text, 'original\n');
    });

    test('interleaved single and multi edits', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello\n';

      // Single edit
      f.replaceAt(0, 'H', config: e.config);
      expect(f.text, 'Hello\n');

      // Multi edit
      applyEdits(f, [TextEdit(1, 2, 'A'), TextEdit(3, 4, 'O')], e.config);
      expect(f.text, 'HAlOo\n');

      // Single edit
      f.insertAt(5, '!', config: e.config);
      expect(f.text, 'HAlOo!\n');

      // Undo all three
      f.undo(); // removes '!'
      expect(f.text, 'HAlOo\n');

      f.undo(); // reverses multi edit
      expect(f.text, 'Hello\n');

      f.undo(); // reverses 'H'
      expect(f.text, 'hello\n');
    });
  });

  group('redo with applyEdits', () {
    test('redo restores edits after undo', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'hello world\n';

      applyEdits(f, [TextEdit(0, 5, 'hi'), TextEdit(6, 11, 'there')], e.config);

      expect(f.text, 'hi there\n');

      f.undo();
      expect(f.text, 'hello world\n');

      f.redo();
      expect(f.text, 'hi there\n');
      expect(f.redoList, isEmpty);
      expect(f.undoList.length, 1);
    });

    test('redo with no history returns null', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'test\n';

      final result = f.redo();

      expect(result, isNull);
    });

    test('new edit clears redo history', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'original\n';

      applyEdits(f, [TextEdit(0, 8, 'first')], e.config);
      f.undo();

      expect(f.redoList.length, 1);

      // New edit should clear redo
      applyEdits(f, [TextEdit(0, 8, 'second')], e.config);

      expect(f.redoList, isEmpty);
    });
  });
}
