import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/file_buffer_text.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';

void main() {
  test('getPositionFromIndex', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();
    expect(f.positionFromByteIndex(0), Position(c: 0, l: 0));
    expect(f.positionFromByteIndex(2), Position(c: 2, l: 0));
    expect(f.positionFromByteIndex(4), Position(c: 0, l: 1));
    expect(f.positionFromByteIndex(6), Position(c: 2, l: 1));
  });

  test('replaceAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    f.replaceAt(Position(c: 0, l: 0), 'X');
    expect(f.text, 'Xbc\ndef\n');
    final undo = f.undoList.last;
    expect(undo.prev, 'a');
    expect(undo.text, 'X');
    expect(undo.i, 0);
  });

  test('deleteRange', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    f.deleteRange(
      Range(
        start: Position(c: 0, l: 0),
        end: Position(c: 1, l: 1),
      ),
    );
    expect(f.text, 'ef\n');
    final undo = f.undoList.last;
    expect(undo.prev, 'abc\nd');
    expect(undo.i, 0);
    expect(f.yankBuffer, 'abc\nd');
  });

  test('insertAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    f.insertAt(Position(c: 0, l: 1), 'X');
    expect(f.text, 'abc\nXdef\n');
    final undo = f.undoList.last;
    expect(undo.prev, '');
    expect(undo.text, 'X');
    expect(undo.i, 4);
  });

  test('deleteAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    f.deleteAt(Position(c: 0, l: 1));
    expect(f.text, 'abc\nef\n');
    final undo = f.undoList.last;
    expect(undo.prev, 'd');
    expect(undo.text, '');
    expect(undo.i, 4);
  });

  test('deleteAt last on line', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.deleteAt(Position(c: 0, l: 2));
    f.deleteAt(Position(c: 0, l: 2));
    f.deleteAt(Position(c: 0, l: 2));
    expect(f.text, 'abc\ndef\n\n');
  });

  test('multiple undo', () {
    final e = Editor();
    final f = FileBuffer();
    f.text = 'abc\nd👩‍👩‍👦‍👦f\nghi\n';
    f.createLines();
    f.deleteRange(Range(
      start: Position(c: 0, l: 0),
      end: Position(c: 0, l: 1),
    ));
    f.deleteAt(Position(c: 0, l: 0));
    f.deleteAt(Position(c: 0, l: 0));
    f.replaceAt(Position(c: 0, l: 0), 'X');
    expect(f.text, 'X\nghi\n');
    actionUndo(e, f);
    expect(f.text, 'f\nghi\n');
    actionUndo(e, f);
    expect(f.text, '👩‍👩‍👦‍👦f\nghi\n');
    actionUndo(e, f);
    expect(f.text, 'd👩‍👩‍👦‍👦f\nghi\n');
    actionUndo(e, f);
    expect(f.text, 'abc\nd👩‍👩‍👦‍👦f\nghi\n');
  });

  test('deleteAt with emoji', () {
    final f = FileBuffer();
    f.text = 'ab🪼de\n';
    f.createLines();
    f.deleteAt(Position(c: 2, l: 0));
    expect(f.text, 'abde\n');
  });

  test('replaceAt with emoji', () {
    final f = FileBuffer();
    f.text = 'ab🪼de\n';
    f.createLines();
    f.replaceAt(Position(c: 2, l: 0), 'X');
    expect(f.text, 'abXde\n');
  });
}
