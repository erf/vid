import 'package:test/test.dart';
import 'package:vid/actions_insert.dart';
import 'package:vid/actions_normal.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/modes.dart';
import 'package:vid/position.dart';

void main() {
  test('defaultInsert', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\n';
    f.createLines();
    f.cursor = Position(c: 1, l: 0);
    actionInsert(e, f);
    defaultInsert(f, 'd');
    expect(f.text, 'adbc\n');
    expect(f.cursor, Position(c: 2, l: 0));
  });

  test('insertActionEscape', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc';
    f.createLines();
    f.cursor = Position(c: 0, l: 0);
    actionInsert(e, f);
    insertActionEscape(f);
    expect(f.mode, Mode.normal);
  });

  test('insertActionEnter', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abcdef\n';
    f.createLines();
    f.cursor = Position(c: 3, l: 0);
    actionInsert(e, f);
    insertActionEnter(f);
    expect(f.text, 'abc\ndef\n');
    expect(f.cursor, Position(c: 0, l: 1));
  });

  test('insertActionBackspace', () {
    final e = Editor();
    final f = e.fileBuffer;
    f.text = 'abc\ndef\nghi\n';
    f.createLines();
    f.cursor = Position(c: 0, l: 1);
    insertActionBackspace(f);
    expect(f.text, 'abcdef\nghi\n');
    expect(f.cursor, Position(c: 3, l: 0));
  });
}
