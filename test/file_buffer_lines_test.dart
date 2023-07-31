import 'package:test/test.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';

void main() {
  test('createLines', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();
    expect(f.lines.length, 2);
    expect(f.lines[0].text.string, 'abc ');
    expect(f.lines[1].text.string, 'def ');
  });

  test('createLines w newline at end', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(f.lines.length, 2);
    expect(f.lines[0].text.string, 'abc ');
    expect(f.lines[1].text.string, 'def ');
  });
}
