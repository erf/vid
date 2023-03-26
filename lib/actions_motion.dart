import 'dart:math';

import 'file_buffer.dart';
import 'text_utils.dart';
import 'types.dart';

typedef Motion = Position Function(Position);

final motionActions = <String, Motion>{
  'h': motionCharPrev,
  'l': motionCharNext,
  'j': motionCharDown,
  'k': motionCharUp,
  'g': motionFirstLine,
  'G': motionLastLine,
  'w': motionWordNext,
  'b': motionWordPrev,
  'e': motionWordEnd,
  '0': motionLineStart,
  '\$': motionLineEnd,
};

Position motionCharNext(Position p) {
  return Position(
    line: p.line,
    char: clamp(p.char + 1, 0, lines[p.line].length - 1),
  );
}

Position motionCharPrev(Position p) {
  return Position(line: p.line, char: max(0, p.char - 1));
}

Position motionCharUp(Position p) {
  final line = max(p.line - 1, 0);
  final char = min(p.char, lines[line].length - 1);
  return Position(line: line, char: char);
}

Position motionCharDown(Position p) {
  final line = min(p.line + 1, lines.length - 1);
  final char = min(p.char, lines[line].length - 1);
  return Position(line: line, char: char);
}

Position motionFirstLine(Position p) {
  return Position(line: 0, char: 0);
}

Position motionLastLine(Position position) {
  return Position(line: max(0, lines.length - 1), char: lines.last.length);
}

Position motionLineStart(Position p) {
  return Position(line: p.line, char: 0);
}

Position motionLineEnd(Position p) {
  return Position(line: p.line, char: lines[p.line].length);
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
