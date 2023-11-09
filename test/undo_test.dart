import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/file_buffer_text.dart';
import 'package:vid/position.dart';

void main() {
  test('test undo', () {
    final e = Editor();
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(f.modified, false);
    f.deleteAt(Position(c: 0, l: 0));
    expect(f.modified, true);
    NormalActions.undo(e, f);
    expect(f.modified, false);
  });
}
