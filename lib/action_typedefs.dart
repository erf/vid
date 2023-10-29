import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef InsertFun = void Function(FileBuffer);

typedef NormalFun = void Function(Editor, FileBuffer);

typedef OperatorFun = void Function(FileBuffer, Range);

typedef TextObjectFun = Range Function(FileBuffer, Position);

typedef MotionFun = Position Function(FileBuffer, Position);

typedef FindFun = Position Function(FileBuffer, Position, String, bool incl);
