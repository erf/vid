import 'dart:math';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef TextObject = Range Function(Position);

final textObjects = <String, TextObject>{
  'd': objectCurrentLine,
  'y': objectCurrentLine,
  'k': objectLineUp,
  'j': objectLineDown,
  'g': objectFirstLine,
  'G': objectLastLine,
};

Range objectCurrentLine(Position p) {
  return Range(
    start: Position(line: p.line, char: 0),
    end: Position(line: p.line, char: lines[p.line].length),
  );
}

Range objectLineUp(Position p) {
  final start = Position(line: max(p.line - 1, 0), char: 0);
  final end = Position(line: p.line, char: lines[p.line].length);
  return Range(start: start, end: end);
}

Range objectLineDown(Position p) {
  final start = Position(line: p.line, char: 0);
  final endLine = min(p.line + 1, lines.length - 1);
  final end = Position(line: endLine, char: lines[endLine].length);
  return Range(start: start, end: end);
}

Range objectFirstLine(Position p) {
  final start = Position(line: p.line, char: lines[p.line].length);
  final end = motionFirstLine(p);
  return Range(start: start, end: end);
}

Range objectLastLine(Position p) {
  final start = Position(line: p.line, char: 0);
  final end = motionLastLine(p);
  return Range(start: start, end: end);
}
