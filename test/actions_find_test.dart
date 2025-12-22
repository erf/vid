import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/actions/motions.dart';
import 'package:vid/editor.dart';

void main() {
  test('motionFindNextChar', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abca\ndef\n';
    // 'abca\ndef\n' - cursor at 0
    // Looking for 'a' from offset 0 -> next 'a' is at offset 3
    // Looking for 'b' from offset 0 -> 'b' is at offset 1
    // Looking for 'c' from offset 0 -> 'c' is at offset 2
    f.edit.findStr = 'a';
    expect(Motions.findNextChar(e, f, 0), 3);
    f.edit.findStr = 'b';
    expect(Motions.findNextChar(e, f, 0), 1);
    f.edit.findStr = 'c';
    expect(Motions.findNextChar(e, f, 0), 2);
  });

  test('motionFindPrevChar', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // 'abc\ndef\n' - cursor at offset 2 (char 'c')
    // Looking for 'a' from offset 2 -> 'a' is at offset 0
    // Looking for 'b' from offset 2 -> 'b' is at offset 1
    // Looking for 'c' from offset 2 -> 'c' is at offset 2 (itself)
    f.edit.findStr = 'a';
    expect(Motions.findPrevChar(e, f, 2), 0);
    f.edit.findStr = 'b';
    expect(Motions.findPrevChar(e, f, 2), 1);
    f.edit.findStr = 'c';
    expect(Motions.findPrevChar(e, f, 2), 2);
  });

  test('till with delete operator', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'this is a test\n';
    f.cursor = 0;
    f.edit.findStr = 't';
    e.input('dt');
    expect(f.text, 'test\n');
  });

  test('find with delete operator', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'this is a test\n';
    f.cursor = 0;
    f.edit.findStr = 't';
    e.input('df');
    expect(f.text, 'est\n');
  });
}
