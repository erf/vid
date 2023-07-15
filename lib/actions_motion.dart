import 'dart:math';

import 'package:vid/file_buffer_ext.dart';

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
  return Position(y: p.y, x: max(0, f.lines[p.y].length - 1));
}

Position motionWordNext(FileBuffer f, Position p) {
  final start = f.getIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text, start);
  if (matches.isEmpty) {
    return p;
  }
  final match =
      matches.firstWhere((m) => m.start > start, orElse: () => matches.first);
  return f.getPositionFromIndex(match.start);
}

Position motionWordEnd(FileBuffer f, Position p) {
  final start = f.getIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text, start);
  if (matches.isEmpty) {
    return p;
  }
  final match =
      matches.firstWhere((m) => m.end - 1 > start, orElse: () => matches.first);
  return f.getPositionFromIndex(match.end - 1);
}

Position motionWordPrev(FileBuffer f, Position p) {
  final line = f.lines[p.y];
  final start = line.charsToByteLength(p.x);
  final matches = RegExp(r'\w+').allMatches(line.string);
  final reversed = matches.toList().reversed;
  for (final match in reversed) {
    if (match.start < start) {
      final charPos = line.byteToCharsLength(match.start);
      return Position(x: charPos, y: p.y);
    }
  }
  // either move to previous line or stay on the first char
  if (p.y > 0) {
    return motionWordPrev(f, Position(x: f.lines[p.y - 1].length, y: p.y - 1));
  } else {
    return Position(x: 0, y: p.y);
  }
}

// exit insert mode
Position motionEscape(FileBuffer f, Position p) {
  f.mode = Mode.normal;
  f.pendingAction = null;
  return p;
}

// find the next occurence of the given character on the current line
Position motionFindNextChar(FileBuffer f, Position p, String char) {
  final line = f.lines[p.y];
  final start = line.charsToByteLength(p.x + 1);
  final match = char.allMatches(line.string, start).firstOrNull;
  if (match == null) {
    return p;
  }
  final charPos = line.byteToCharsLength(match.start);
  return Position(x: charPos, y: p.y);
}

Position motionTillNextChar(FileBuffer f, Position position, String char) {
  final p = motionFindNextChar(f, position, char);
  p.x = max(p.x - 1, position.x);
  return p;
}

// find the previous occurence of the given character on the current line
Position motionFindPrevChar(FileBuffer f, Position position, String char) {
  final line = f.lines[position.y];
  final start = line.charsToByteLength(position.x);
  final matches = char.allMatches(line.string.substring(0, start));
  if (matches.isEmpty) {
    return position;
  }
  final match = matches.last;
  final charPos = line.byteToCharsLength(match.start);
  return Position(x: charPos, y: position.y);
}

Position motionTillPrevChar(FileBuffer f, Position position, String char) {
  final p = motionFindPrevChar(f, position, char);
  p.x = min(p.x + 1, position.x);
  return p;
}
