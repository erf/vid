import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef NormalFn = void Function(Editor, FileBuffer);

typedef InsertFn = void Function(FileBuffer);

typedef OperatorFn = void Function(FileBuffer, Range);

typedef MotionFn = Position Function(FileBuffer, Position, bool incl);

typedef FindFn = Position Function(FileBuffer, Position, String, bool incl);

typedef CommandFn = void Function(Editor e, FileBuffer f, List<String> args);
