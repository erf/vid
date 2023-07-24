import 'package:test/test.dart';
import 'package:vid/actions_pending.dart';
import 'package:vid/actions_text_objects.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('pendingActionDelete on objectCurrentLine', () {
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
}
