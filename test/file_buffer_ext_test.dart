import 'package:test/test.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('getIndexFromPosition', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(f.getIndexFromPosition(Position(x: 0, y: 0)), 0);
    expect(f.getIndexFromPosition(Position(x: 2, y: 0)), 2);
    expect(f.getIndexFromPosition(Position(x: 0, y: 1)), 4);
    expect(f.getIndexFromPosition(Position(x: 2, y: 1)), 6);
  });

  test('getPositionFromIndex', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(f.getPositionFromIndex(0), Position(x: 0, y: 0));
    expect(f.getPositionFromIndex(2), Position(x: 2, y: 0));
    expect(f.getPositionFromIndex(4), Position(x: 0, y: 1));
    expect(f.getPositionFromIndex(6), Position(x: 2, y: 1));
  });
}
