import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef InsertAction = void Function(FileBuffer);

typedef NormalAction = void Function(Editor, FileBuffer);

typedef OperatorAction = void Function(FileBuffer, Range);

typedef TextObjectAction = Range Function(FileBuffer, Position);

typedef MotionAction = Position Function(FileBuffer, Position);

typedef FindAction = Position Function(
    FileBuffer, Position, String, bool inclusive);
