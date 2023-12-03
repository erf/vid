import 'dart:math';

import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'caret.dart';

class Find {
  // find the next occurence of the given character on the current line
  static Caret findNextChar(FileBuffer f, Caret p, String c, bool incl) {
    final pnext = Caret(c: p.c + 1, l: p.l);
    final start = f.byteIndexFromPosition(pnext);
    final match = c.allMatches(f.text, start).firstOrNull;
    if (match == null) return p;
    final newpos = f.positionFromByteIndex(match.start);
    if (incl) newpos.c++;
    return newpos;
  }

  // find the next occurence of the given character
  static Caret tillNextChar(FileBuffer f, Caret p, String c, bool incl) {
    final pnext = findNextChar(f, p, c, incl);
    pnext.c = max(pnext.c - 1, p.c);
    return pnext;
  }

  // find the previous occurence of the given character on the current line
  static Caret findPrevChar(FileBuffer f, Caret p, String c, bool incl) {
    final start = f.byteIndexFromPosition(p);
    final matches = c.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    final match = matches.last;
    return f.positionFromByteIndex(match.start);
  }

  // find the previous occurence of the given character
  static Caret tillPrevChar(FileBuffer f, Caret p, String c, bool incl) {
    final prev = findPrevChar(f, p, c, incl);
    prev.c = min(prev.c + 1, p.c);
    return prev;
  }
}
