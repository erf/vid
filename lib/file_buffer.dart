import 'position.dart';

enum Mode { normal, pending, insert, replace }

String? filename;

var lines = [""]; // always have at least one line with one empty string

var cursor = Position();

var view = Position();

var mode = Mode.normal;

Function? currentPendingAction;
