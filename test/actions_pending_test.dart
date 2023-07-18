import 'package:test/test.dart';
import 'package:vid/actions_pending.dart';
import 'package:vid/actions_text_objects.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('deleteLine', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi'.ch;
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.lines.map((e) => e.text).toList(), [
      'abc'.ch,
      'ghi'.ch,
    ]);
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('delete last line', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi'.ch;
    f.createLines();
    f.cursor = Position(c: 0, l: 2);
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r);
    expect(f.lines.map((e) => e.text), [
      'abc'.ch,
      'def'.ch,
      ''.ch,
    ]);
  });
}
