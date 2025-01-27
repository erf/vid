import 'package:vid/file_buffer_io.dart';
import 'package:vid/file_buffer_text.dart';

import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class FindNextCharMotion extends Motion {
  const FindNextCharMotion({super.inclusive = true, super.linewise});

  @override
  Position run(FileBuffer f, Position p, {String? c}) {
    bool hasOperator = f.edit.op != null;
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    final pnext = Position(c: p.c + 1, l: p.l);
    final int start = f.byteIndexFromPosition(pnext);
    final Match? match = f.edit.findStr!.allMatches(f.text, start).firstOrNull;
    if (match == null) return p;
    final Position newpos = f.positionFromByteIndex(match.start);
    if (inclusive && hasOperator) newpos.c++;
    return newpos;
  }
}
