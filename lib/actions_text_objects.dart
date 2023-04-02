import 'dart:math';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef TextObject = Range Function(FileBuffer, Position);

Range objectCurrentLine(FileBuffer f, Position p) {
  return Range(
    start: Position(line: p.line, char: 0),
    end: Position(line: p.line, char: f.lines[p.line].length),
  );
}

Range objectLineUp(FileBuffer f, Position p) {
  final start = Position(line: max(p.line - 1, 0), char: 0);
  final end = Position(line: p.line, char: f.lines[p.line].length);
  return Range(start: start, end: end);
}

Range objectLineDown(FileBuffer f, Position p) {
  final start = Position(line: p.line, char: 0);
  final endLine = min(p.line + 1, f.lines.length - 1);
  final end = Position(line: endLine, char: f.lines[endLine].length);
  return Range(start: start, end: end);
}

Range objectFirstLine(FileBuffer f, Position p) {
  final start = Position(line: p.line, char: f.lines[p.line].length);
  final end = motionFirstLine(f, p);
  return Range(start: start, end: end);
}

Range objectLastLine(FileBuffer f, Position p) {
  final start = Position(line: p.line, char: 0);
  final end = motionLastLine(f, p);
  return Range(start: start, end: end);
}
