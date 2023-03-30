import 'dart:math';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'position.dart';
import 'text_utils.dart';

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
  '\x1b': motionEscape,
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
  final line = clamp(p.line - 1, 0, lines.length - 1);
  final char = clamp(p.char, 0, lines[line].length - 1);
  return Position(line: line, char: char);
}

Position motionCharDown(Position p) {
  final line = clamp(p.line + 1, 0, lines.length - 1);
  final char = clamp(p.char, 0, lines[line].length - 1);
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
  return Position(line: p.line, char: lines[p.line].length - 1);
}

Position motionWordNext(Position p) {
  final line = lines[p.line];
  final charPos = line.symbolToByteLength(p.char);
  final matches = RegExp(r'\S+').allMatches(line.string);
  for (final match in matches) {
    if (match.start > charPos) {
      final symbolPos = line.byteToSymbolLength(match.start);
      return Position(char: symbolPos, line: p.line);
    }
  }
  // either move to next line or stay on last char
  if (p.line < lines.length - 1) {
    return motionWordNext(Position(char: -1, line: p.line + 1));
  } else {
    return Position(char: max(line.length - 1, 0), line: p.line);
  }
}

Position motionWordEnd(Position p) {
  final line = lines[p.line];
  final charPos = line.symbolToByteLength(p.char);
  final matches = RegExp(r'\S+').allMatches(line.string);
  for (final match in matches) {
    if (match.end - 1 > charPos) {
      final symbolPos = line.byteToSymbolLength(match.start);
      return Position(char: symbolPos - 1, line: p.line);
    }
  }
  if (p.line < lines.length - 1) {
    return motionWordEnd(Position(char: 0, line: p.line + 1));
  } else {
    return Position(char: max(line.length - 1, 0), line: p.line);
  }
}

Position motionWordPrev(Position p) {
  final line = lines[p.line];
  final matches = RegExp(r'\S+').allMatches(line.string);
  if (matches.isEmpty) {
    return Position(char: p.char, line: p.line);
  }
  final charPos = line.symbolToByteLength(p.char);
  final reversed = matches.toList().reversed;
  for (final match in reversed) {
    if (match.start < charPos) {
      final symbolPos = line.byteToSymbolLength(match.start);
      return Position(char: symbolPos, line: p.line);
    }
  }
  // either move to previous line or stay on the first char
  if (p.line > 0) {
    return motionWordPrev(Position(
      line: p.line - 1,
      char: lines[p.line - 1].length,
    ));
  } else {
    return Position(char: 0, line: p.line);
  }
}

Position motionEscape(Position p) {
  mode = Mode.normal;
  currentPending = null;
  return p;
}
