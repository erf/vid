import 'dart:math';

import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'position.dart';

typedef FindAction = Position Function(FileBuffer, Position, String);

// find the next occurence of the given character on the current line
Position findNextChar(FileBuffer f, Position p, String char) {
  final pnew = Position(c: p.c + 1, l: p.l);
  final start = f.byteIndexFromPosition(pnew);
  final match = char.allMatches(f.text, start).firstOrNull;
  if (match == null) return p;
  return f.positionFromByteIndex(match.start);
}

// find the next occurence of the given character
Position tillNextChar(FileBuffer f, Position p, String char) {
  final pnew = findNextChar(f, p, char);
  pnew.c = max(pnew.c - 1, p.c);
  return pnew;
}

// find the previous occurence of the given character on the current line
Position findPrevChar(FileBuffer f, Position p, String char) {
  final start = f.byteIndexFromPosition(p);
  final matches = char.allMatches(f.text.substring(0, start));
  if (matches.isEmpty) return p;
  final match = matches.last;
  return f.positionFromByteIndex(match.start);
}

// find the previous occurence of the given character
Position tillPrevChar(FileBuffer f, Position p, String char) {
  final pnew = findPrevChar(f, p, char);
  pnew.c = min(pnew.c + 1, p.c);
  return pnew;
}
