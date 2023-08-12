import 'dart:math';

import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'position.dart';

class Find {
// find the next occurence of the given character on the current line
  static Position findNextChar(
      FileBuffer f, Position p, String char, bool inclusive) {
    final pnew = Position(c: p.c + 1, l: p.l);
    final start = f.byteIndexFromPosition(pnew);
    final match = char.allMatches(f.text, start).firstOrNull;
    if (match == null) return p;
    final newPos = f.positionFromByteIndex(match.start);
    if (inclusive) {
      newPos.c++;
      return newPos;
    }
    return newPos;
  }

// find the next occurence of the given character
  static Position tillNextChar(
      FileBuffer f, Position p, String char, bool inclusive) {
    final pnew = findNextChar(f, p, char, inclusive);
    pnew.c = max(pnew.c - 1, p.c);
    return pnew;
  }

// find the previous occurence of the given character on the current line
  static Position findPrevChar(
      FileBuffer f, Position p, String char, bool inclusive) {
    final start = f.byteIndexFromPosition(p);
    final matches = char.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    final match = matches.last;
    return f.positionFromByteIndex(match.start);
  }

// find the previous occurence of the given character
  static Position tillPrevChar(
      FileBuffer f, Position p, String char, bool inclusive) {
    final pnew = findPrevChar(f, p, char, inclusive);
    pnew.c = min(pnew.c + 1, p.c);
    return pnew;
  }
}
