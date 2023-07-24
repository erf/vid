import 'package:test/test.dart';
import 'package:vid/actions_pending.dart';
import 'package:vid/actions_text_objects.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('pendingActionDelete on objectCurrentLine (first)', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, 'def\nghi');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('pendingActionDelete on objectCurrentLine (middle)', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, 'abc\nghi');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('pendingActionDelete on objectCurrentLine (last)', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(c: 0, l: 2);
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, 'abc\ndef');
  });

  test('pendingActionDelete on objectCurrentLine (one-line)', () {
    final f = FileBuffer();
    f.text = 'abc';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, '');
  });

  test('pendingActionDelete on objectCurrentLine (one-line w newline)', () {
    final f = FileBuffer();
    f.text = 'abc\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, '');
  });

  test('pendingActionDelete on objectLineUp', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    final r = objectLineUp(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, 'ghi');
    expect(f.cursor, Position(c: 0, l: 0));
  });
  test('pendingActionDelete on objectLineUp (last line)', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 2);
    final r = objectLineUp(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, 'abc\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('pendingActionDelete on objectLineDown (middle line)', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(l: 1, c: 0);
    final r = objectLineDown(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.text, 'abc\n');
    expect(f.cursor, Position(l: 1, c: 0));
  });
}
