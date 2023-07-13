import 'package:test/test.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('joinLines', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
      'ghi'.ch,
    ];
    f.cursor = Position(x: 0, y: 1);
    f.joinLines();
    expect(f.lines, [
      'abc'.ch,
      'defghi'.ch,
    ]);
    expect(f.cursor, Position(x: 0, y: 1));
  });
}
