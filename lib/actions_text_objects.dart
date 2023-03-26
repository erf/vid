import 'dart:math';

import 'package:vid/actions_motion.dart';

import 'file_buffer.dart';
import 'types.dart';

typedef TextObject = Range Function(Position);

final textObjects = <String, TextObject>{
  'd': objectCurrentLine,
  'k': objectLineUp,
  'j': objectLineDown,
  'g': objectFirstLine,
  'G': objectLastLine,
};

Range objectCurrentLine(Position p) {
  return Range(
    p0: Position(line: p.line, char: 0),
    p1: Position(line: p.line, char: lines[p.line].length),
  );
}

Range objectLineUp(Position p) {
  final p0 = Position(line: max(p.line - 1, 0), char: 0);
  final p1 = Position(line: p.line, char: lines[p.line].length);
  return Range(p0: p0, p1: p1);
}

Range objectLineDown(Position p) {
  final p0 = Position(line: p.line, char: 0);
  final endLine = min(p.line + 1, lines.length - 1);
  final p1 = Position(
    line: endLine,
    char: lines[endLine].length,
  );
  return Range(p0: p0, p1: p1);
}

Range objectFirstLine(Position p) {
  final p0 = Position(line: p.line, char: lines[p.line].length);
  final p1 = motionFirstLine(p);
  return Range(p0: p0, p1: p1);
}

Range objectLastLine(Position p) {
  final p0 = Position(line: p.line, char: 0);
  final p1 = motionLastLine(p);
  return Range(p0: p0, p1: p1);
}
