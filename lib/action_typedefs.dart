import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef InsertFn = void Function(FileBuffer);

typedef NormalFn = void Function(Editor, FileBuffer);

typedef OperatorFn = void Function(FileBuffer, Range);

typedef MotionFn = Caret Function(FileBuffer, Caret, bool incl);

typedef FindFn = Caret Function(FileBuffer, Caret, String, bool incl);
