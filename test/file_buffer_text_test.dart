import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/actions/normal_actions.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/modes.dart';
import 'package:vid/range.dart';

void main() {
  test('replaceAt', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.replaceAt(0, 'X', config: e.config);
    expect(f.text, 'Xbc\ndef\n');
    final op = f.undoList.last.ops.first;
    expect(op.prevText, 'a');
    expect(op.newText, 'X');
    expect(op.start, 0);
  });

  test('deleteRange', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Range from start (0) to 'd' at offset 5 (exclusive end)
    f.deleteRange(Range(0, 5), config: e.config);
    expect(f.text, 'ef\n');
    final op = f.undoList.last.ops.first;
    expect(op.prevText, 'abc\nd');
    expect(op.start, 0);
    // Note: deleteRange does not auto-yank anymore - operators handle yank explicitly
  });

  test('insertAt', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Insert at start of 'def' line (offset 4)
    f.insertAt(4, 'X', config: e.config);
    expect(f.text, 'abc\nXdef\n');
    final op = f.undoList.last.ops.first;
    expect(op.prevText, '');
    expect(op.newText, 'X');
    expect(op.start, 4);
  });

  test('deleteAt', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Delete at start of 'def' line (offset 4)
    f.deleteAt(4, config: e.config);
    expect(f.text, 'abc\nef\n');
    final op = f.undoList.last.ops.first;
    expect(op.prevText, 'd');
    expect(op.newText, '');
    expect(op.start, 4);
  });

  test('deleteAt last on line', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    // 'ghi' line starts at offset 8
    f.deleteAt(8); // delete 'g'
    f.deleteAt(8); // delete 'h'
    f.deleteAt(8); // delete 'i'
    expect(f.text, 'abc\ndef\n\n');
  });

  test('deleteAt with emoji', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'ab🪼de\n';
    // 'ab' is 2 bytes, then emoji at offset 2
    f.deleteAt(2);
    expect(f.text, 'abde\n');
  });

  test('replaceAt with emoji', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'ab🪼de\n';
    // 'ab' is 2 bytes, then emoji at offset 2
    f.replaceAt(2, 'X');
    expect(f.text, 'abXde\n');
  });

  test('multiple undo', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    e.file = FileBuffer(text: 'abc\nd👩‍👩‍👦‍👦f\nghi\n');
    final f = e.file;
    // Delete range from 0 to start of second line content ('d')
    // 'abc\n' is 4 bytes, so offset 4 is 'd'
    f.deleteRange(Range(0, 4), config: e.config); // removes 'abc\n'
    f.deleteAt(0, config: e.config); // removes 'd'
    f.deleteAt(0, config: e.config); // removes emoji (👩‍👩‍👦‍👦)
    f.replaceAt(0, 'X', config: e.config); // replaces 'f'
    expect(f.text, 'X\nghi\n');
    const Undo()(e, f);
    expect(f.text, 'f\nghi\n');
    const Undo()(e, f);
    expect(f.text, '👩‍👩‍👦‍👦f\nghi\n');
    const Undo()(e, f);
    expect(f.text, 'd👩‍👩‍👦‍👦f\nghi\n');
    const Undo()(e, f);
    expect(f.text, 'abc\nd👩‍👩‍👦‍👦f\nghi\n');
  });

  test('redo', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello world\n123\n';
    e.input('dw');
    expect(f.text, 'world\n123\n');
    e.input('u');
    expect(f.text, 'hello world\n123\n');
    e.input('U');
    expect(f.text, 'world\n123\n');
    e.input('dd');
    expect(f.text, '123\n');
    e.input('u');
    expect(f.text, 'world\n123\n');
    e.input('U');
    expect(f.text, '123\n');
  });

  test('undo restores visual mode and selection', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = 0;

    // Enter visual mode and select 'hello'
    e.input('v'); // enter visual mode
    expect(f.mode, Mode.visual);
    e.input('llll'); // extend selection to cover 'hello'

    // Selection should now span 'hello' (0 to 4)
    expect(f.selection.start, 0);
    expect(f.selection.end, 4);

    // Delete selection
    e.input('d');
    expect(f.text, ' world\n');
    expect(f.mode, Mode.normal);

    // Undo should restore visual mode and selection
    e.input('u');
    expect(f.text, 'hello world\n');
    expect(f.mode, Mode.visual);
    expect(f.selection.start, 0);
    expect(f.selection.end, 4);
  });

  test('undo from normal mode operator stays in normal mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = 0;

    // Delete word using operator+motion (normal mode)
    e.input('dw');
    expect(f.text, 'world\n');
    expect(f.mode, Mode.normal);

    // Undo should stay in normal mode
    e.input('u');
    expect(f.text, 'hello world\n');
    expect(f.mode, Mode.normal);
  });

  test('delete last newline undo should not create extra newline', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'a\n';
    f.cursor = 0; // at 'a' - normal mode cursor can't be on newline
    e.input('xu');
    expect(f.text, 'a\n');
    expect(f.cursor, 0);
  });

  test('delete newline at end of file', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n\n';
    // Empty line starts at offset 8
    f.cursor = 8;
    e.input('dd');
    expect(f.text, 'abc\ndef\n');
    expect(f.lineNumber(f.cursor), 1);
  });
}
