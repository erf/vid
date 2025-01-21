import 'package:test/test.dart';
import 'package:vid/actions/normal.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/file_buffer_text.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';
import 'package:vid/terminal_dummy.dart';

void main() {
  test('getPositionFromIndex', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(f.positionFromByteIndex(0), Position(c: 0, l: 0));
    expect(f.positionFromByteIndex(2), Position(c: 2, l: 0));
    expect(f.positionFromByteIndex(4), Position(c: 0, l: 1));
    expect(f.positionFromByteIndex(6), Position(c: 2, l: 1));
  });

  test('replaceAt', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    f.replaceAt(e, Position(c: 0, l: 0), 'X');
    expect(f.text, 'Xbc\ndef\n');
    final op = f.undoList.last;
    expect(op.prevText, 'a');
    expect(op.newText, 'X');
    expect(op.start, 0);
  });

  test('deleteRange', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    f.deleteRange(e, Range(Position(c: 0, l: 0), Position(c: 1, l: 1)));
    expect(f.text, 'ef\n');
    final op = f.undoList.last;
    expect(op.prevText, 'abc\nd');
    expect(op.start, 0);
    expect(f.yankBuffer, 'abc\nd');
  });

  test('insertAt', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    f.insertAt(e, Position(c: 0, l: 1), 'X');
    expect(f.text, 'abc\nXdef\n');
    final op = f.undoList.last;
    expect(op.prevText, '');
    expect(op.newText, 'X');
    expect(op.start, 4);
  });

  test('deleteAt', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    f.deleteAt(e, Position(c: 0, l: 1));
    expect(f.text, 'abc\nef\n');
    final op = f.undoList.last;
    expect(op.prevText, 'd');
    expect(op.newText, '');
    expect(op.start, 4);
  });

  test('deleteAt last on line', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\nghi\n';
    f.createLines(e, WrapMode.none);
    f.deleteAt(e, Position(c: 0, l: 2));
    f.deleteAt(e, Position(c: 0, l: 2));
    f.deleteAt(e, Position(c: 0, l: 2));
    expect(f.text, 'abc\ndef\n\n');
  });

  test('deleteAt with emoji', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'ab🪼de\n';
    f.createLines(e, WrapMode.none);
    f.deleteAt(e, Position(c: 2, l: 0));
    expect(f.text, 'abde\n');
  });

  test('replaceAt with emoji', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'ab🪼de\n';
    f.createLines(e, WrapMode.none);
    f.replaceAt(e, Position(c: 2, l: 0), 'X');
    expect(f.text, 'abXde\n');
  });

  test('multiple undo', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    e.file = FileBuffer(text: 'abc\nd👩‍👩‍👦‍👦f\nghi\n');
    final f = e.file;
    f.createLines(e, WrapMode.none);
    f.deleteRange(
        e,
        Range(
          Position(c: 0, l: 0),
          Position(c: 0, l: 1),
        ));
    f.deleteAt(e, Position(c: 0, l: 0));
    f.deleteAt(e, Position(c: 0, l: 0));
    f.replaceAt(e, Position(c: 0, l: 0), 'X');
    expect(f.text, 'X\nghi\n');
    Normal.undo(e, f);
    expect(f.text, 'f\nghi\n');
    Normal.undo(e, f);
    expect(f.text, '👩‍👩‍👦‍👦f\nghi\n');
    Normal.undo(e, f);
    expect(f.text, 'd👩‍👩‍👦‍👦f\nghi\n');
    Normal.undo(e, f);
    expect(f.text, 'abc\nd👩‍👩‍👦‍👦f\nghi\n');
  });

  test('redo', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello world\n123\n';
    f.createLines(e, WrapMode.none);
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

  test('delete last newline undo should not create extra newline', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'a\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 1, l: 0);
    e.input('xu');
    expect(f.text, 'a\n');
    expect(f.cursor, Position(c: 1, l: 0));
  });

  test('delete newline at end of file', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 2);
    e.input('dd');
    expect(f.text, 'abc\ndef\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });
}
