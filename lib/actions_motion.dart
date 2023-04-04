import 'dart:math';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';
import 'utils.dart';

typedef Motion = Position Function(FileBuffer, Position);

Position motionCharNext(FileBuffer f, Position p) {
  return Position(
    y: p.y,
    x: clamp(p.x + 1, 0, f.lines[p.y].length - 1),
  );
}

Position motionCharPrev(FileBuffer f, Position p) {
  return Position(
    y: p.y,
    x: max(0, p.x - 1),
  );
}

Position motionCharUp(FileBuffer f, Position p) {
  final line = clamp(p.y - 1, 0, f.lines.length - 1);
  final char = clamp(p.x, 0, f.lines[line].length - 1);
  return Position(y: line, x: char);
}

Position motionCharDown(FileBuffer f, Position p) {
  final line = clamp(p.y + 1, 0, f.lines.length - 1);
  final char = clamp(p.x, 0, f.lines[line].length - 1);
  return Position(y: line, x: char);
}

Position motionFileStart(FileBuffer f, Position p) {
  return Position(y: 0, x: 0);
}

Position motionFileEnd(FileBuffer f, Position position) {
  return Position(
    x: f.lines.last.length,
    y: max(0, f.lines.length - 1),
  );
}

Position motionLineStart(FileBuffer f, Position p) {
  return Position(y: p.y, x: 0);
}

Position motionLineEnd(FileBuffer f, Position p) {
  return Position(y: p.y, x: f.lines[p.y].length - 1);
}

Position motionWordNext(FileBuffer f, Position p) {
  final line = f.lines[p.y];
  final start = line.charsToByteLength(p.x);
  final matches = RegExp(r'\S+').allMatches(line.string);
  for (final match in matches) {
    if (match.start > start) {
      final charPos = line.byteToCharsLength(match.start);
      return Position(x: charPos, y: p.y);
    }
  }
  // either move to next line or stay on last char
  if (p.y < f.lines.length - 1) {
    return Position(x: 0, y: p.y + 1);
  } else {
    return Position(x: max(line.length - 1, 0), y: p.y);
  }
}

Position motionWordEnd(FileBuffer f, Position p) {
  final line = f.lines[p.y];
  final start = line.charsToByteLength(p.x);
  final matches = RegExp(r'\S+').allMatches(line.string);
  for (final match in matches) {
    if (match.end - 1 > start) {
      final charPos = line.byteToCharsLength(match.end);
      return Position(x: charPos - 1, y: p.y);
    }
  }
  if (p.y < f.lines.length - 1) {
    return Position(x: 0, y: p.y + 1);
  } else {
    return Position(x: max(line.length - 1, 0), y: p.y);
  }
}

Position motionWordPrev(FileBuffer f, Position p) {
  final line = f.lines[p.y];
  final start = line.charsToByteLength(p.x);
  final matches = RegExp(r'\S+').allMatches(line.string);
  final reversed = matches.toList().reversed;
  for (final match in reversed) {
    if (match.start < start) {
      final charPos = line.byteToCharsLength(match.start);
      return Position(x: charPos, y: p.y);
    }
  }
  // either move to previous line or stay on the first char
  if (p.y > 0) {
    return Position(x: f.lines[p.y - 1].length, y: p.y - 1);
  } else {
    return Position(x: 0, y: p.y);
  }
}

// TODO not a motion, but a command ?
Position motionEscape(FileBuffer f, Position p) {
  f.mode = Mode.normal;
  f.currentPending = null;
  return p;
}
