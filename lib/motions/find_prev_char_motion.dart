import 'package:vid/file_buffer_io.dart';
import 'package:vid/file_buffer_text.dart';

import '../file_buffer.dart';
import '../position.dart';
import 'motion.dart';

class FindPrevCharMotion extends Motion {
  const FindPrevCharMotion({this.c});

  final String? c;

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    f.edit.findStr = c ?? f.edit.findStr ?? f.readNextChar();
    final int start = f.byteIndexFromPosition(p);
    final matches = f.edit.findStr!.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    final Match match = matches.last;
    return f.positionFromByteIndex(match.start);
  }
}
