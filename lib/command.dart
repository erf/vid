import 'editor.dart';
import 'file_buffer.dart';
import 'position.dart';
import 'range.dart';

sealed class Command<T extends Function> {
  T action;

  Command(this.action);
}

typedef InsertAction = void Function(FileBuffer);

class InsertCommand extends Command<InsertAction> {
  InsertCommand(super.action);
}

typedef NormalAction = void Function(Editor, FileBuffer);

class NormalCommand extends Command<NormalAction> {
  NormalCommand(super.action);
}

typedef OperatorAction = void Function(FileBuffer, Range);

class OperatorCommand extends Command<OperatorAction> {
  OperatorCommand(super.action);
}

typedef TextObjectAction = Range Function(FileBuffer, Position);

class TextObjectCommand extends Command<TextObjectAction> {
  TextObjectCommand(super.action);
}

typedef MotionAction = Position Function(FileBuffer, Position);

class MotionCommand extends Command<MotionAction> {
  MotionCommand(super.action);
}

typedef FindAction = Position Function(
    FileBuffer, Position, String, bool inclusive);

class FindCommand extends Command<FindAction> {
  FindCommand(super.action);
}
