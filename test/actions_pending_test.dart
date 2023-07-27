import 'package:test/test.dart';
import 'package:vid/actions_operator.dart';
import 'package:vid/actions_text_objects.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('pendingActionDelete on objectCurrentLine', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    final r = objectCurrentLine(f, f.cursor);
    operatorActionDelete(f, r);
    expect(f.text, 'def\nghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('pendingActionDelete on objectLineUp', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    final r = objectLineUp(f, f.cursor);
    operatorActionDelete(f, r);
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });

  test('pendingActionDelete on objectLineDown', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 0);
    final r = objectLineDown(f, f.cursor);
    operatorActionDelete(f, r);
    expect(f.text, 'ghi\n');
    expect(f.cursor, Position(c: 0, l: 0));
  });
}
