import 'actions.dart';

sealed class Command<T extends Function> {
  T action;

  Command(this.action);
}

class InsertCommand extends Command<InsertAction> {
  InsertCommand(super.action);
}

class NormalCommand extends Command<NormalAction> {
  NormalCommand(super.action);
}

class OperatorCommand extends Command<OperatorAction> {
  OperatorCommand(super.action);
}

class TextObjectCommand extends Command<TextObjectAction> {
  TextObjectCommand(super.action);
}

class MotionCommand extends Command<MotionAction> {
  MotionCommand(super.action);
}

class FindCommand extends Command<FindAction> {
  FindCommand(super.action);
}
