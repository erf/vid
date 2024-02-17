import 'package:test/test.dart';
import 'package:vid/actions_find.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';

void main() {
  test('motionFindNextChar', () {
    final f = FileBuffer();
    f.text = 'abca\ndef\n';
    f.createLines(WrapMode.none, 80, 24);
    final cursor = Position(c: 0, l: 0);
    expect(Find.findNextChar(f, cursor, 'a', false), Position(c: 3, l: 0));
    expect(Find.findNextChar(f, cursor, 'b', false), Position(c: 1, l: 0));
    expect(Find.findNextChar(f, cursor, 'c', false), Position(c: 2, l: 0));
    // inclusive
    expect(Find.findNextChar(f, cursor, 'a', true), Position(c: 4, l: 0));
    expect(Find.findNextChar(f, cursor, 'b', true), Position(c: 2, l: 0));
    expect(Find.findNextChar(f, cursor, 'c', true), Position(c: 3, l: 0));
  });

  test('motionFindPrevChar', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines(WrapMode.none, 80, 24);
    final cursor = Position(c: 2, l: 0);
    expect(Find.findPrevChar(f, cursor, 'a', false), Position(c: 0, l: 0));
    expect(Find.findPrevChar(f, cursor, 'b', false), Position(c: 1, l: 0));
    expect(Find.findPrevChar(f, cursor, 'c', false), Position(c: 2, l: 0));
  });

  test('till with delete operator', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'this is a test\n';
    f.createLines(WrapMode.none, 80, 24);
    f.cursor = Position(c: 0, l: 0);
    f.edit.findStr = 't';
    e.input('dt');
    expect(f.text, 'test\n');
  });

  test('find with delete operator', () {
    final e = Editor(redraw: false);
    final f = e.file;
    f.text = 'this is a test\n';
    f.createLines(WrapMode.none, 80, 24);
    f.cursor = Position(c: 0, l: 0);
    f.edit.findStr = 't';
    e.input('df');
    expect(f.text, 'est\n');
  });
}
