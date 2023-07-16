import 'package:test/test.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';
import 'package:vid/undo.dart';

void main() {
  test('getIndexFromPosition', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(f.getIndexFromPosition(Position(x: 0, y: 0)), 0);
    expect(f.getIndexFromPosition(Position(x: 2, y: 0)), 2);
    expect(f.getIndexFromPosition(Position(x: 0, y: 1)), 4);
    expect(f.getIndexFromPosition(Position(x: 2, y: 1)), 6);
  });

  test('getPositionFromIndex', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(f.getPositionFromIndex(0), Position(x: 0, y: 0));
    expect(f.getPositionFromIndex(2), Position(x: 2, y: 0));
    expect(f.getPositionFromIndex(4), Position(x: 0, y: 1));
    expect(f.getPositionFromIndex(6), Position(x: 2, y: 1));
  });

  test('replaceAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();
    f.replaceAt(Position(x: 0, y: 0), 'X');
    expect(f.text, 'Xbc\ndef');
    final undo = f.undoList.last;
    expect(undo.oldText, 'a');
    expect(undo.newText, 'X');
    expect(undo.index, 0);
    expect(undo.end, 1);
  });

  test('deleteRange', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();
    f.deleteRange(
      Range(
        p0: Position(x: 0, y: 0),
        p1: Position(x: 1, y: 1),
      ),
    );
    expect(f.text, 'ef');
    final undo = f.undoList.last;
    expect(undo.oldText, 'abc\nd');
    expect(undo.index, 0);
    expect(undo.end, 5);
  });

  test('insertAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();
    f.insertAt(Position(x: 0, y: 1), 'X');
    expect(f.text, 'abc\nXdef');
    final undo = f.undoList.last;
    expect(undo.oldText, '');
    expect(undo.newText, 'X');
    expect(undo.index, 4);
    expect(undo.end, 4);
  });
}
