import 'package:test/test.dart';
import 'package:vid/actions_text_objects.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';

void main() {
  test('objectCurrentLine', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    Range r = objectCurrentLine(f, f.cursor);
    expect(r.start, Position(l: 1, c: 0));
    expect(r.end, Position(l: 1, c: 4));
  });

  test('objectLineUp', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(l: 1, c: 0);
    Range r = objectLineUp(f, f.cursor);
    expect(r.start, Position(l: 0, c: 0));
    expect(r.end, Position(l: 1, c: 4));
  });

  test('objectLineDown', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(l: 1, c: 0);
    Range r = objectLineDown(f, f.cursor);
    expect(r.start, Position(l: 1, c: 0));
    expect(r.end, Position(l: 2, c: 4));
  });
}
