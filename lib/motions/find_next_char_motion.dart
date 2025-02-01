import 'package:vid/file_buffer_io.dart';
import 'package:vid/file_buffer_text.dart';

import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class FindNextCharMotion extends Motion {
  const FindNextCharMotion({
    this.c,
    super.inclusive = true,
    super.linewise,
  });

  final String? c;

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    final Position next = Position(c: p.c + 1, l: p.l);
    final int start = f.byteIndexFromPosition(next);
    final Match? match = f.edit.findStr!.allMatches(f.text, start).firstOrNull;
    if (match == null) return p;
    final Position matchPos = f.positionFromByteIndex(match.start);
    if (inclusive && op) matchPos.c++;
    return matchPos;
  }
}
