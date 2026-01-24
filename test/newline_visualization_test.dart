import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/selection.dart';

void main() {
  test('LineEnd motion moves cursor to newline position', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 0; // at 'a'
    e.input('\$'); // move to end of line
    expect(f.cursor, 3); // at newline position
    expect(f.text[f.cursor], '\n');
  });

  test('LineEnd motion on empty line stays at newline', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = '\ndef\n';
    f.cursor = 0; // at empty line's newline
    e.input('\$'); // move to end of line
    expect(f.cursor, 0); // stays at newline
  });

  test('delete (x) on newline joins lines', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.cursor = 3; // at newline after 'abc'
    e.input('x');
    expect(f.text, 'abcdef\n');
    expect(f.cursor, 3); // cursor stays at same position
  });

  test('\$ then x joins lines', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello\nworld\n';
    f.cursor = 0;
    e.input('\$x'); // move to end of line, delete newline
    expect(f.text, 'helloworld\n');
    expect(f.cursor, 5);
  });

  test('delete newline on empty line joins with next', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n\ndef\n';
    f.cursor = 4; // at empty line's newline
    e.input('x');
    expect(f.text, 'abc\ndef\n');
  });

  test('multi-cursor on newlines, x joins all', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'a\nb\nc\n';
    // Set up multiple cursors at each newline position
    f.selections = [
      Selection.collapsed(1), // first newline
      Selection.collapsed(3), // second newline
    ];
    e.input('x'); // delete with all cursors
    // Both newlines deleted, so all lines joined
    expect(f.text, 'abc\n');
  });

  test('undo after deleting newline', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'line1\nline2\n';
    f.cursor = 5; // at first newline
    e.input('x'); // delete newline
    expect(f.text, 'line1line2\n');
    e.input('u'); // undo
    expect(f.text, 'line1\nline2\n');
    expect(f.cursor, 5);
  });

  test('l (right) can reach newline', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'ab\n';
    f.cursor = 0; // at 'a'
    e.input('l'); // move right to 'b'
    expect(f.cursor, 1);
    e.input('l'); // move right to newline
    expect(f.cursor, 2);
    expect(f.text[f.cursor], '\n');
  });

  test('cursor on trailing newline of file', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'last line\n';
    f.cursor = 0;
    e.input('\$'); // move to end of line
    expect(f.cursor, 9); // at the trailing newline
    expect(f.text[f.cursor], '\n');
  });

  test('newlineSymbol config default is space', () {
    const config = Config();
    expect(config.newlineSymbol, ' ');
  });

  test('newlineSymbol config can be customized', () {
    final config = Config.fromMap({'newlineSymbol': '¬'});
    expect(config.newlineSymbol, '¬');
  });

  test('newlineSymbol config preserves custom value in copyWith', () {
    final config = Config(newlineSymbol: '↩');
    final updated = config.copyWith(tabWidth: 2);
    expect(updated.newlineSymbol, '↩');
  });
}
