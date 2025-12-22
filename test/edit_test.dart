import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';

void main() {
  test('make sure action is reset on wrong key in normal mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('Æ');
    expect(f.input.cmdKey, '');
    expect(f.cursor, 0);
    expect(f.text, 'abc\n');
  });

  test('make sure action is reset on wrong key in operator mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('dÆ');
    expect(f.input.cmdKey, '');
    expect(f.cursor, 0);
    expect(f.text, 'abc\n');
  });

  test('make sure prev action is correct in normal mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('dw');
    expect(f.text, '\n');
    expect(f.input.cmdKey, '');
    // prevEdit no longer stores cmdKey - it only stores operation data
    expect(f.prevEdit, isNotNull);
    expect(f.prevEdit!.op, isNotNull);
  });

  test('make sure prev motion is correct in normal mode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\n';
    f.cursor = 0;
    e.input('w');
    expect(f.input.cmdKey, '');
  });
}
