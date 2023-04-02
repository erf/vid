import 'dart:math';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';
import 'utils.dart';

typedef Motion = Position Function(FileBuffer, Position);

Position motionCharNext(FileBuffer f, Position p) {
  return Position(
    line: p.line,
    char: clamp(p.char + 1, 0, f.lines[p.line].length - 1),
  );
}

Position motionCharPrev(FileBuffer f, Position p) {
  return Position(line: p.line, char: max(0, p.char - 1));
}

Position motionCharUp(FileBuffer f, Position p) {
  final line = clamp(p.line - 1, 0, f.lines.length - 1);
  final char = clamp(p.char, 0, f.lines[line].length - 1);
  return Position(line: line, char: char);
}

Position motionCharDown(FileBuffer f, Position p) {
  final line = clamp(p.line + 1, 0, f.lines.length - 1);
  final char = clamp(p.char, 0, f.lines[line].length - 1);
  return Position(line: line, char: char);
}

Position motionFirstLine(FileBuffer f, Position p) {
  return Position(line: 0, char: 0);
}

Position motionLastLine(FileBuffer f, Position position) {
  return Position(line: max(0, f.lines.length - 1), char: f.lines.last.length);
}

Position motionLineStart(FileBuffer f, Position p) {
  return Position(line: p.line, char: 0);
}

Position motionLineEnd(FileBuffer f, Position p) {
  return Position(line: p.line, char: f.lines[p.line].length - 1);
}

Position motionWordNext(FileBuffer f, Position p) {
  final line = f.lines[p.line];
  final start = line.charsToByteLength(p.char);
  final matches = RegExp(r'\S+').allMatches(line.string);
  for (final match in matches) {
    if (match.start > start) {
      final charPos = line.byteToCharsLength(match.start);
      return Position(char: charPos, line: p.line);
    }
  }
  // either move to next line or stay on last char
  if (p.line < f.lines.length - 1) {
    return Position(char: 0, line: p.line + 1);
  } else {
    return Position(char: max(line.length - 1, 0), line: p.line);
  }
}

Position motionWordEnd(FileBuffer f, Position p) {
  final line = f.lines[p.line];
  final start = line.charsToByteLength(p.char);
  final matches = RegExp(r'\S+').allMatches(line.string);
  for (final match in matches) {
    if (match.end - 1 > start) {
      final charPos = line.byteToCharsLength(match.end);
      return Position(char: charPos - 1, line: p.line);
    }
  }
  if (p.line < f.lines.length - 1) {
    return Position(char: 0, line: p.line + 1);
  } else {
    return Position(char: max(line.length - 1, 0), line: p.line);
  }
}

Position motionWordPrev(FileBuffer f, Position p) {
  final line = f.lines[p.line];
  final start = line.charsToByteLength(p.char);
  final matches = RegExp(r'\S+').allMatches(line.string);
  final reversed = matches.toList().reversed;
  for (final match in reversed) {
    if (match.start < start) {
      final charPos = line.byteToCharsLength(match.start);
      return Position(char: charPos, line: p.line);
    }
  }
  // either move to previous line or stay on the first char
  if (p.line > 0) {
    return Position(char: f.lines[p.line - 1].length, line: p.line - 1);
  } else {
    return Position(char: 0, line: p.line);
  }
}

// TODO not a motion, but a command ?
Position motionEscape(FileBuffer f, Position p) {
  f.mode = Mode.normal;
  f.currentPending = null;
  return p;
}
