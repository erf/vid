import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef TextObject = Range Function(Position);

final textObjects = <String, TextObject>{
  'd': objectCurrentLine,
};

Range objectCurrentLine(Position p) {
  return Range(
    p0: Position(line: p.line, char: 0),
    p1: Position(line: p.line, char: lines[p.line].length),
  );
}
