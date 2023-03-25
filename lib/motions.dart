import 'dart:math';

import 'file_buffer.dart';
import 'position.dart';
import 'utils.dart';

typedef Motion = Position Function(Position);

Position motionCharNext(Position p) {
  return Position(
    line: p.line,
    char: clamp(p.char + 1, 0, lines[p.line].length - 1),
  );
}

Position motionCharPrev(Position p) {
  return Position(line: p.line, char: max(0, p.char - 1));
}

Position motionFirstLine(Position p) {
  return Position(line: 0, char: 0);
}

Position motionBottomLine(Position position) {
  return Position(line: max(0, lines.length - 1), char: 0);
}

Position motionLineStart(Position p) {
  return Position(line: p.line, char: 0);
}

Position motionLineEnd(Position p) {
  return Position(line: p.line, char: lines[p.line].length - 1);
}

Position motionLineUp(Position p) {
  final line = clamp(p.line - 1, 0, lines.length - 1);
  final char = clamp(p.char, 0, lines[line].length - 1);
  return Position(line: line, char: char);
}

Position motionLineDown(Position p) {
  final line = clamp(p.line + 1, 0, lines.length - 1);
  final char = clamp(p.char, 0, lines[line].length - 1);
  return Position(line: line, char: char);
}

Position motionWordNext(Position p) {
  int start = p.char;
  final line = lines[p.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return p;
  }
  for (var match in matches) {
    if (match.start > start) {
      return Position(char: match.start, line: p.line);
    }
  }
  return Position(char: matches.last.end, line: p.line);
}

Position motionWordEnd(Position p) {
  final start = p.char;
  final line = lines[p.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return Position(line: p.line, char: start);
  }
  for (var match in matches) {
    if (match.end - 1 > start) {
      return Position(line: p.line, char: match.end - 1);
    }
  }
  return Position(line: p.line, char: matches.last.end);
}

Position motionWordPrev(Position p) {
  final start = p.char;
  final line = lines[p.line];
  final matches = RegExp(r'\S+').allMatches(line);
  if (matches.isEmpty) {
    return Position(char: start, line: p.line);
  }
  final reversed = matches.toList().reversed;
  for (var match in reversed) {
    if (match.start < start) {
      return Position(char: match.start, line: p.line);
    }
  }
  return Position(char: matches.first.start, line: p.line);
}
