import 'editor.dart';
import 'file_buffer.dart';
import 'caret.dart';
import 'range.dart';

typedef InsertFn = void Function(FileBuffer);

typedef NormalFn = void Function(Editor, FileBuffer);

typedef OperatorFn = void Function(FileBuffer, Range);

typedef MotionFn = Position Function(FileBuffer, Position, bool incl);

typedef FindFn = Position Function(FileBuffer, Position, String, bool incl);
