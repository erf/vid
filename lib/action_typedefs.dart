import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef InsertFn = void Function(FileBuffer);

typedef NormalFn = void Function(Editor, FileBuffer);

typedef OperatorFn = void Function(FileBuffer, Range);

typedef TextObjectFn = Range Function(FileBuffer, Position);

typedef MotionFn = Position Function(FileBuffer, Position);

typedef FindFn = Position Function(FileBuffer, Position, String, bool incl);
