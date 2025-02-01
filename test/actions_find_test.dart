import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/motions/find_next_char_motion.dart';
import 'package:vid/motions/find_prev_char_motion.dart';
import 'package:vid/position.dart';
import 'package:vid/terminal_dummy.dart';

void main() {
  test('motionFindNextChar', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abca\ndef\n';
    f.createLines(e, WrapMode.none);
    final cursor = Position(c: 0, l: 0);
    expect(FindNextCharMotion(c: 'a').run(f, cursor), Position(c: 3, l: 0));
    expect(FindNextCharMotion(c: 'b').run(f, cursor), Position(c: 1, l: 0));
    expect(FindNextCharMotion(c: 'c').run(f, cursor), Position(c: 2, l: 0));
  });

  test('motionFindPrevChar', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    final cursor = Position(c: 2, l: 0);
    expect(FindPrevCharMotion(c: 'a').run(f, cursor), Position(c: 0, l: 0));
    expect(FindPrevCharMotion(c: 'b').run(f, cursor), Position(c: 1, l: 0));
    expect(FindPrevCharMotion(c: 'c').run(f, cursor), Position(c: 2, l: 0));
  });

  test('till with delete operator', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'this is a test\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 0);
    f.edit.findStr = 't';
    e.input('dt');
    expect(f.text, 'test\n');
  });

  test('find with delete operator', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'this is a test\n';
    f.createLines(e, WrapMode.none);
    f.cursor = Position(c: 0, l: 0);
    f.edit.findStr = 't';
    e.input('df');
    expect(f.text, 'est\n');
  });
}
