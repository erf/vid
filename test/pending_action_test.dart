import 'package:test/test.dart';
import 'package:vid/actions_pending.dart';
import 'package:vid/actions_text_objects.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('deleteLine', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(x: 0, y: 1);
    final e = Editor();
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r, '');
    expect(f.lines, [
      'abc'.ch,
      'ghi'.ch,
    ]);
    expect(f.cursor, Position(x: 0, y: 1));
  });

  test('delete last line', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(x: 0, y: 2);
    final e = Editor();
    final r = objectCurrentLine(f, f.cursor);
    pendingActionDelete(f, r, '');
    // TODO: should we delete the last line?
    // the range does not include the last newline on the previous line
    // so a new line is created
    expect(f.lines, [
      'abc'.ch,
      'def'.ch,
      ''.ch,
    ]);
  });
}
