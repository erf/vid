import 'dart:math';

import 'actions_motion.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

class TextObjects {
  static Range currentLine(FileBuffer f, Position p) {
    int endline = min(p.l, f.lines.length - 1);
    return Range(
      start: Position(l: p.l, c: 0),
      end: Position(l: endline, c: f.lines[endline].charLen),
    );
  }

  static Range lineUp(FileBuffer f, Position p) {
    final start = Position(l: max(0, p.l - 1), c: 0);
    final end = Position(l: p.l, c: f.lines[p.l].charLen);
    return Range(start: start, end: end);
  }

  static Range lineDown(FileBuffer f, Position p) {
    final start = Position(l: p.l, c: 0);
    final line = min(p.l + 1, f.lines.length - 1);
    final end = Position(l: line, c: f.lines[line].charLen);
    return Range(start: start, end: end);
  }

  static Range firstLine(FileBuffer f, Position p) {
    final start = Position(l: p.l, c: f.lines[p.l].charLen);
    final end = Motions.fileStart(f, p);
    return Range(start: start, end: end);
  }

  static Range lastLine(FileBuffer f, Position p) {
    final start = Position(l: p.l, c: 0);
    final end = Motions.fileEnd(f, p);
    return Range(start: start, end: end);
  }
}
