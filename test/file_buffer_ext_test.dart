import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('getIndexFromPosition', () {
    final f = FileBuffer();
    f.text = 'abc\ndef'.ch;
    f.createLines();
    expect(f.charIndexFromPosition(Position(c: 0, l: 0)), 0);
    expect(f.charIndexFromPosition(Position(c: 2, l: 0)), 2);
    expect(f.charIndexFromPosition(Position(c: 0, l: 1)), 4);
    expect(f.charIndexFromPosition(Position(c: 2, l: 1)), 6);
  });

  test('getPositionFromIndex', () {
    final f = FileBuffer();
    f.text = 'abc\ndef'.ch;
    f.createLines();
    expect(f.positionFromByteIndex(0), Position(c: 0, l: 0));
    expect(f.positionFromByteIndex(2), Position(c: 2, l: 0));
    expect(f.positionFromByteIndex(4), Position(c: 0, l: 1));
    expect(f.positionFromByteIndex(6), Position(c: 2, l: 1));
  });

  test('replaceAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef'.ch;
    f.createLines();
    f.replaceAt(Position(c: 0, l: 0), 'X'.ch);
    expect(f.text, 'Xbc\ndef'.ch);
    final undo = f.undoList.last;
    expect(undo.oldText, 'a'.ch);
    expect(undo.newText, 'X'.ch);
    expect(undo.index, 0);
    expect(undo.end, 1);
  });

  test('deleteRange', () {
    final f = FileBuffer();
    f.text = 'abc\ndef'.ch;
    f.createLines();
    f.deleteRange(
      Range(
        start: Position(c: 0, l: 0),
        end: Position(c: 1, l: 1),
      ),
    );
    expect(f.text, 'ef'.ch);
    final undo = f.undoList.last;
    expect(undo.oldText, 'abc\nd'.ch);
    expect(undo.index, 0);
    expect(undo.end, 5);
  });

  test('insertAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef'.ch;
    f.createLines();
    f.insertAt(Position(c: 0, l: 1), 'X'.ch);
    expect(f.text, 'abc\nXdef'.ch);
    final undo = f.undoList.last;
    expect(undo.oldText, ''.ch);
    expect(undo.newText, 'X'.ch);
    expect(undo.index, 4);
    expect(undo.end, 4);
  });

  test('deleteAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef'.ch;
    f.createLines();
    f.deleteAt(Position(c: 0, l: 1));
    expect(f.text, 'abc\nef'.ch);
    final undo = f.undoList.last;
    expect(undo.oldText, 'd'.ch);
    expect(undo.newText, ''.ch);
    expect(undo.index, 4);
    expect(undo.end, 5);
  });

  test('deleteAt last on line', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi'.ch;
    f.createLines();
    f.deleteAt(Position(c: 0, l: 2));
    f.deleteAt(Position(c: 0, l: 2));
    f.deleteAt(Position(c: 0, l: 2));
    expect(f.text, 'abc\ndef\n'.ch);
    expect(f.lines.map((e) => e.text), [
      'abc'.ch,
      'def'.ch,
      ''.ch,
    ]);
  });

  test('multiple undo', () {
    final e = Editor();
    final f = FileBuffer();
    f.text = 'abc\nd👩‍👩‍👦‍👦f\nghi'.ch;
    f.createLines();
    f.deleteRange(Range(
      start: Position(c: 0, l: 0),
      end: Position(c: 0, l: 1),
    ));
    f.deleteAt(Position(c: 0, l: 0));
    f.deleteAt(Position(c: 0, l: 0));
    f.replaceAt(Position(c: 0, l: 0), 'X'.ch);
    expect(f.text, 'X\nghi'.ch);
    actionUndo(e, f);
    expect(f.text, 'f\nghi'.ch);
    actionUndo(e, f);
    expect(f.text, '👩‍👩‍👦‍👦f\nghi'.ch);
    actionUndo(e, f);
    expect(f.text, 'd👩‍👩‍👦‍👦f\nghi'.ch);
    actionUndo(e, f);
    expect(f.text, 'abc\nd👩‍👩‍👦‍👦f\nghi'.ch);
  });

  test('deleteAt with emoji', () {
    final f = FileBuffer();
    f.text = 'ab🪼de'.ch;
    f.createLines();
    f.deleteAt(Position(c: 2, l: 0));
    expect(f.text, 'abde'.ch);
  });

  test('replaceAt with emoji', () {
    final f = FileBuffer();
    f.text = 'ab🪼de'.ch;
    f.createLines();
    f.replaceAt(Position(c: 2, l: 0), 'X'.ch);
    expect(f.text, 'abXde'.ch);
  });
}
