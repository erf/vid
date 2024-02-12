import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';

void main() {
  test('createLines', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines(WrapMode.none, 80, 24);
    expect(f.lines.length, 2);
    expect(f.lines[0].ch.string, 'abc ');
    expect(f.lines[1].ch.string, 'def ');
  });

  test('createLines w newline at end', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines(WrapMode.none, 80, 24);
    expect(f.lines.length, 2);
    expect(f.lines[0].ch.string, 'abc ');
    expect(f.lines[1].ch.string, 'def ');
  });

  test('createLines with wordwrap', () {
    final f = FileBuffer();
    f.text = 'abc def ghi jkl';
    f.createLines(WrapMode.word, 8, 10);
    expect(f.lines.length, 2);
    expect(f.lines[0].ch.string, 'abc def ');
    expect(f.lines[1].ch.string, 'ghi jkl ');
  });

  test('createLines with emoji at end', () {
    final f = FileBuffer();
    f.text = 'abc def😀\nghi jkl\n';
    f.createLines(WrapMode.none, 8, 20);
    expect(f.lines.length, 2);
    expect(f.lines[0].ch.string, 'abc def😀 ');
    expect(f.lines[1].ch.string, 'ghi jkl ');
  });
}
