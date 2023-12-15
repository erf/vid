import 'package:test/test.dart';
import 'package:vid/actions_command.dart';
import 'package:vid/editor.dart';
import 'package:vid/position.dart';

void main() {
  test('substitute should delete the first occurrence of a pattern', () {
    final e = Editor();
    final f = e.file;
    f.text = 'hello world';
    f.cursor = Position(l: 0, c: 0);
    CommandActions.substitute(e, f, ['s/l//']);
    expect(f.text, equals('helo world\n'));
  });

  test('substitute should replace the first occurrence of a pattern', () {
    final e = Editor();
    final f = e.file;
    f.text = 'hello world';
    f.cursor = Position(l: 0, c: 0);
    CommandActions.substitute(e, f, ['s/world/friend/']);
    expect(f.text, equals('hello friend\n'));
  });

  test('substitute should replace multiple occurrences of a pattern', () {
    final e = Editor();
    final f = e.file;
    f.text = 'this is fun fun fun';
    f.cursor = Position(l: 0, c: 0);
    CommandActions.substitute(e, f, ['s/fun/cool/g']);
    expect(f.text, equals('this is cool cool cool\n'));
  });
}
