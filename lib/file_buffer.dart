import 'package:characters/characters.dart';

import 'actions_operator_pending.dart';
import 'types.dart';

String? filename;

// always have at least one line with one empty string
List<Characters> lines = ["".characters];

var cursor = Position();

var view = Position();

var mode = Mode.normal;

OperatorPendingAction? currentPending;

int? count;

Characters? yankBuffer;
