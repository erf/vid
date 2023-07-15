import 'dart:math';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef TextObject = Range Function(FileBuffer, Position);

Range objectCurrentLine(FileBuffer f, Position p) {
  return Range(
    p0: Position(y: p.y, x: 0),
    p1: Position(y: p.y, x: f.lines[p.y].length + 1),
  );
}

Range objectLineUp(FileBuffer f, Position p) {
  final start = Position(y: max(p.y - 1, 0), x: 0);
  final end = Position(y: p.y, x: f.lines[p.y].length);
  return Range(p0: start, p1: end);
}

Range objectLineDown(FileBuffer f, Position p) {
  final start = Position(y: p.y, x: 0);
  final endLine = min(p.y + 1, f.lines.length - 1);
  final end = Position(y: endLine, x: f.lines[endLine].length);
  return Range(p0: start, p1: end);
}

Range objectFirstLine(FileBuffer f, Position p) {
  final start = Position(y: p.y, x: f.lines[p.y].length);
  final end = motionFileStart(f, p);
  return Range(p0: start, p1: end);
}

Range objectLastLine(FileBuffer f, Position p) {
  final start = Position(y: p.y, x: 0);
  final end = motionFileEnd(f, p);
  return Range(p0: start, p1: end);
}
