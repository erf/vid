import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef InsertFn = void Function(Editor, FileBuffer);

typedef NormalFn = void Function(Editor, FileBuffer);

typedef OperatorFn = void Function(Editor, FileBuffer, Range);

typedef MotionFn = Position Function(FileBuffer, Position, bool incl);

typedef FindFn = Position Function(FileBuffer, Position, String, bool incl);
