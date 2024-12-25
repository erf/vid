import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

typedef NormalFn = void Function(Editor, FileBuffer);

typedef InsertFn = void Function(Editor, FileBuffer);

typedef CommandFn = void Function(Editor, FileBuffer, List<String>);

typedef OperatorFn = void Function(Editor, FileBuffer, Range);

typedef MotionFn = Position Function(FileBuffer, Position, bool);

typedef FindFn = Position Function(FileBuffer, Position, String, bool);

class MotionAction {
  final Function fn;
  final bool linewise;
  final bool? inclusive;
  const MotionAction(this.fn, {this.linewise = false, this.inclusive});
}
