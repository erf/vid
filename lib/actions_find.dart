import 'dart:math';

import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'position.dart';

class Find {
  // find the next occurence of the given character on the current line
  static Position findNextChar(FileBuffer f, Position p, String c, bool incl) {
    final pnext = Position(c: p.c + 1, l: p.l);
    final start = f.byteIndexFromPosition(pnext);
    final match = c.allMatches(f.text, start).firstOrNull;
    if (match == null) return p;
    final newpos = f.positionFromByteIndex(match.start);
    if (incl) {
      newpos.c++;
      return newpos;
    }
    return newpos;
  }

  // find the next occurence of the given character
  static Position tillNextChar(FileBuffer f, Position p, String c, bool incl) {
    final pnext = findNextChar(f, p, c, incl);
    pnext.c = max(pnext.c - 1, p.c);
    return pnext;
  }

  // find the previous occurence of the given character on the current line
  static Position findPrevChar(FileBuffer f, Position p, String c, bool incl) {
    final start = f.byteIndexFromPosition(p);
    final matches = c.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    final match = matches.last;
    return f.positionFromByteIndex(match.start);
  }

  // find the previous occurence of the given character
  static Position tillPrevChar(FileBuffer f, Position p, String c, bool incl) {
    final prev = findPrevChar(f, p, c, incl);
    prev.c = min(prev.c + 1, p.c);
    return prev;
  }
}
