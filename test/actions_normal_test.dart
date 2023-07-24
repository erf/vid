import 'package:test/test.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('joinLines', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    actionJoinLines(e, f);
    expect(f.text, 'abc\ndefghi\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('actionDeleteLineEnd', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    actionDeleteLineEnd(e, f);
    expect(f.text, 'abc\nd\nghi\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionChangeLineEnd', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'hello world\n';
    f.createLines();
    f.cursor = Position(c: 5, l: 0);
    actionChangeLineEnd(e, f);
    expect(f.text, 'hello\n');
  });

  test('actionDeleteCharNext', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 1);
    actionDeleteCharNext(e, f);
    expect(f.text, 'abc\ndf\nghi\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionDeleteCharNext delete newline', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(l: 0, c: 3);
    actionDeleteCharNext(e, f);
    expect(f.text, 'abcdef\n');
    expect(f.cursor, Position(l: 0, c: 3));
  });

  test('actionInsertLineStart', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(c: 2, l: 1);
    actionInsertLineStart(e, f);
    e.inputChar('x', testMode: true);
    expect(f.text, 'abc\nxdef\n');
    expect(f.cursor, Position(c: 1, l: 1));
  });

  test('actionAppendLineEnd', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    actionAppendLineEnd(e, f);
    e.inputChar('x', testMode: true);
    expect(f.text, 'abcx\ndef\n');
  });
}
