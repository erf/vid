import 'package:characters/characters.dart';

import 'actions_operator_pending.dart';
import 'types.dart';

String? filename;

// always have at least one line with one empty string
var lines = [Characters.empty];

// the current cursor position (0 based, in human-readable symbol space as opposed to byte space)
var cursor = Position();

var view = Position();

var mode = Mode.normal;

OperatorPendingAction? currentPending;

int? count;

Characters? yankBuffer;
