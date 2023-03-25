import 'position.dart';

enum Mode { normal, pending, insert, replace }

String? filename;

// always have at least one line with one empty string
List<String> lines = [""];

Position cursor = Position();

Position view = Position();

Mode mode = Mode.normal;

Function? pendingAction;
