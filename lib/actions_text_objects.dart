import 'dart:math';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef TextObject = Range Function(FileBuffer, Position);

Range objectCurrentLine(FileBuffer f, Position p) {
  return Range(
    start: Position(l: p.l, c: 0),
    end: Position(l: p.l, c: f.lines[p.l].charLen),
  );
}

Range objectLineUp(FileBuffer f, Position p) {
  final start = Position(l: max(0, p.l - 1), c: 0);
  final end = Position(l: p.l, c: f.lines[p.l].charLen);
  return Range(start: start, end: end);
}

Range objectLineDown(FileBuffer f, Position p) {
  final start = Position(l: p.l, c: 0);
  final line = min(p.l + 1, f.lines.length - 1);
  final end = Position(l: line, c: f.lines[line].charLen);
  return Range(start: start, end: end);
}

Range objectFirstLine(FileBuffer f, Position p) {
  final start = Position(l: p.l, c: f.lines[p.l].charLen);
  final end = motionFileStart(f, p);
  return Range(start: start, end: end);
}

Range objectLastLine(FileBuffer f, Position p) {
  final start = Position(l: p.l, c: 0);
  final end = motionFileEnd(f, p);
  return Range(start: start, end: end);
}
