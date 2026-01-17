import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/actions/line_edit_actions.dart';
import 'package:vid/editor.dart';

void main() {
  test('substitute should delete the first occurrence of a pattern', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = 0;
    const CmdSubstitute()(e, f, ['s/l//']);
    expect(f.text, equals('helo world\n'));
  });

  test('substitute should replace the first occurrence of a pattern', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = 0;
    const CmdSubstitute()(e, f, ['s/world/friend/']);
    expect(f.text, equals('hello friend\n'));
  });

  test('substitute should replace multiple occurrences of a pattern', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'this is fun fun fun\n';
    f.cursor = 0;
    const CmdSubstitute()(e, f, ['s/fun/cool/g']);
    expect(f.text, equals('this is cool cool cool\n'));
  });

  test('search should find the first occurrence of a pattern', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello world\n';
    f.cursor = 0;
    e.input('/world\n');
    expect(f.cursor, 6); // 'world' starts at byte offset 6
  });
}
