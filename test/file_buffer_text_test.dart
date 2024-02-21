import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/file_buffer_text.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';

void main() {
  test('getPositionFromIndex', () {
    final f = FileBuffer(text: 'abc\ndef');
    f.createLines(WrapMode.none, 80, 24);
    expect(f.positionFromByteIndex(0), Position(c: 0, l: 0));
    expect(f.positionFromByteIndex(2), Position(c: 2, l: 0));
    expect(f.positionFromByteIndex(4), Position(c: 0, l: 1));
    expect(f.positionFromByteIndex(6), Position(c: 2, l: 1));
  });

  test('replaceAt', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    f.replaceAt(Position(c: 0, l: 0), 'X');
    expect(f.text, 'Xbc\ndef\n');
    final op = f.undoList.last;
    expect(op.prevText, 'a');
    expect(op.newText, 'X');
    expect(op.start, 0);
  });

  test('deleteRange', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    f.deleteRange(Range(Position(c: 0, l: 0), Position(c: 1, l: 1)));
    expect(f.text, 'ef\n');
    final op = f.undoList.last;
    expect(op.prevText, 'abc\nd');
    expect(op.start, 0);
    expect(f.yankBuffer, 'abc\nd');
  });

  test('insertAt', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    f.insertAt(Position(c: 0, l: 1), 'X');
    expect(f.text, 'abc\nXdef\n');
    final op = f.undoList.last;
    expect(op.prevText, '');
    expect(op.newText, 'X');
    expect(op.start, 4);
  });

  test('deleteAt', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    f.deleteAt(Position(c: 0, l: 1));
    expect(f.text, 'abc\nef\n');
    final op = f.undoList.last;
    expect(op.prevText, 'd');
    expect(op.newText, '');
    expect(op.start, 4);
  });

  test('deleteAt last on line', () {
    final f = FileBuffer(text: 'abc\ndef\nghi\n');
    f.createLines(WrapMode.none, 80, 24);
    f.deleteAt(Position(c: 0, l: 2));
    f.deleteAt(Position(c: 0, l: 2));
    f.deleteAt(Position(c: 0, l: 2));
    expect(f.text, 'abc\ndef\n\n');
  });

  test('deleteAt with emoji', () {
    final f = FileBuffer(text: 'ab🪼de\n');
    f.createLines(WrapMode.none, 80, 24);
    f.deleteAt(Position(c: 2, l: 0));
    expect(f.text, 'abde\n');
  });

  test('replaceAt with emoji', () {
    final f = FileBuffer(text: 'ab🪼de\n');
    f.createLines(WrapMode.none, 80, 24);
    f.replaceAt(Position(c: 2, l: 0), 'X');
    expect(f.text, 'abXde\n');
  });

  test('multiple undo', () {
    final e = Editor(redraw: false);
    e.file = FileBuffer(text: 'abc\nd👩‍👩‍👦‍👦f\nghi\n');
    final f = e.file;
    f.createLines(WrapMode.none, 80, 24);
    f.deleteRange(Range(
      Position(c: 0, l: 0),
      Position(c: 0, l: 1),
    ));
    f.deleteAt(Position(c: 0, l: 0));
    f.deleteAt(Position(c: 0, l: 0));
    f.replaceAt(Position(c: 0, l: 0), 'X');
    expect(f.text, 'X\nghi\n');
    NormalActions.undo(e, f);
    expect(f.text, 'f\nghi\n');
    NormalActions.undo(e, f);
    expect(f.text, '👩‍👩‍👦‍👦f\nghi\n');
    NormalActions.undo(e, f);
    expect(f.text, 'd👩‍👩‍👦‍👦f\nghi\n');
    NormalActions.undo(e, f);
    expect(f.text, 'abc\nd👩‍👩‍👦‍👦f\nghi\n');
  });

  test('redo', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'hello world\n123\n';
    f.createLines(WrapMode.none, 80, 24);
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
}
