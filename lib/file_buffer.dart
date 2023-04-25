import 'package:characters/characters.dart';

import 'actions_pending.dart';
import 'modes.dart';
import 'position.dart';
import 'string_ext.dart';

class FileBuffer {
  String? path;

// always have at least one line with one empty string
  List<Characters> lines = [''.ch];

// the current cursor position (0 based, in human-readable symbol space as opposed to byte space)
  var cursor = Position();

// the view offset in the file (0 based, in human-readable symbol space as opposed to byte space)
  var view = Position();

  var mode = Mode.normal;

  OperatorPendingAction? currentPending;

  int? count;

  Characters? yankBuffer;
}
