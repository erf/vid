import 'constants.dart';
import 'file_buffer.dart';
import 'line.dart';

extension FileBufferLines on FileBuffer {
  // split text into lines
  void createLines() {
    // split text into lines (remove last empty line)
    final splits = text.split(nl);
    if (text.endsWith('\n')) splits.removeLast();

    // split text into lines with metadata used for cursor positioning etc.
    lines.clear();
    int byteStart = 0;
    for (int i = 0; i < splits.length; i++) {
      final lineWithSpace = '${splits[i]} ';
      lines.add(Line(lineWithSpace, lineNo: i, byteStart: byteStart));
      byteStart += lineWithSpace.length;
    }
  }

  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;
}
