import 'dart:math';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef TextObject = Range Function(FileBuffer, Position);

Range objectCurrentLine(FileBuffer f, Position p) {
  final lLen = f.lines.length;
  if (lLen == 1) {
    return Range(
      start: Position(l: 0, c: 0),
      end: Position(l: 0, c: f.lines.last.charLen),
    );
  }
  if (p.l >= lLen - 1) {
    return Range(
      start: Position(l: lLen - 2, c: f.lines[lLen - 2].charLen),
      end: Position(l: lLen - 1, c: f.lines.last.charLen),
    );
  }
  return Range(
    start: Position(l: p.l, c: 0),
    end: Position(l: p.l + 1, c: 0),
  );
}

Range objectLineUp(FileBuffer f, Position p) {
  if (p.l == 0) {
    return Range(
      start: Position(l: 0, c: 0),
      end: Position(l: p.l + 1, c: 0),
    );
  }
  final start = Position(l: p.l - 1, c: 0);
  final end = Position(l: p.l + 1, c: 0);
  return Range(start: start, end: end);
}

Range objectLineDown(FileBuffer f, Position p) {
  final start = Position(l: p.l, c: 0);
  final end = Position(l: min(p.l + 2, f.lines.length - 1), c: 0);
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
