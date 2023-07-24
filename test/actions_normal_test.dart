import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('joinLines', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    final e = Editor();
    actionJoinLines(e, f);
    expect(f.text, 'abc\ndefghi');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('actionDeleteLineEnd', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    final e = Editor();
    actionDeleteLineEnd(e, f);
    expect(f.text, 'abc\nd\nghi');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('actionChangeLineEnd', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'hello world';
    f.createLines();
    f.cursor = Position(c: 5, l: 0);
    actionChangeLineEnd(e, f);
    expect(f.text, 'hello');
  });

  test('actionDeleteCharNext', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\nghi';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    final e = Editor();
    actionDeleteCharNext(e, f);
    expect(f.text, 'abc\ndf\nghi');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionDeleteCharNext at end', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n ';
    f.createLines();
    f.cursor = Position(c: 0, l: 2);
    final e = Editor();
    actionDeleteCharNext(e, f);
    expect(f.text, 'abc\ndef\n');
    expect(f.cursor, Position(c: 0, l: 2));
  });
}
