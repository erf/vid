import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/file_buffer_text.dart';
import 'package:vid/caret.dart';
import 'package:vid/range.dart';

void main() {
  test('getPositionFromIndex', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();
    expect(f.positionFromByteIndex(0), Caret(c: 0, l: 0));
    expect(f.positionFromByteIndex(2), Caret(c: 2, l: 0));
    expect(f.positionFromByteIndex(4), Caret(c: 0, l: 1));
    expect(f.positionFromByteIndex(6), Caret(c: 2, l: 1));
  });

  test('replaceAt', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    f.replaceAt(Caret(c: 0, l: 0), 'X');
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
        Caret(c: 0, l: 0),
        Caret(c: 1, l: 1),
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
    f.insertAt(Caret(c: 0, l: 1), 'X');
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
    f.deleteAt(Caret(c: 0, l: 1));
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
    f.deleteAt(Caret(c: 0, l: 2));
    f.deleteAt(Caret(c: 0, l: 2));
    f.deleteAt(Caret(c: 0, l: 2));
    expect(f.text, 'abc\ndef\n\n');
  });

  test('multiple undo', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\nd👩‍👩‍👦‍👦f\nghi\n';
    f.createLines();
    f.deleteRange(Range(
      Caret(c: 0, l: 0),
      Caret(c: 0, l: 1),
    ));
    f.deleteAt(Caret(c: 0, l: 0));
    f.deleteAt(Caret(c: 0, l: 0));
    f.replaceAt(Caret(c: 0, l: 0), 'X');
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

  test('deleteAt with emoji', () {
    final f = FileBuffer();
    f.text = 'ab🪼de\n';
    f.createLines();
    f.deleteAt(Caret(c: 2, l: 0));
    expect(f.text, 'abde\n');
  });

  test('replaceAt with emoji', () {
    final f = FileBuffer();
    f.text = 'ab🪼de\n';
    f.createLines();
    f.replaceAt(Caret(c: 2, l: 0), 'X');
    expect(f.text, 'abXde\n');
  });
}
