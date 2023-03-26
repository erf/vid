import 'types.dart';

String? filename;

// always have at least one line with one empty string
List<String> lines = [""];

Position cursor = Position();

Position view = Position();

Mode mode = Mode.normal;

Function? currentPending;
