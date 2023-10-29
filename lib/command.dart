import 'action_typedefs.dart';

sealed class Command<T extends Function> {
  T action;

  Command(this.action);
}

class InsertCommand extends Command<InsertFun> {
  InsertCommand(super.action);
}

class NormalCommand extends Command<NormalFun> {
  NormalCommand(super.action);
}

class OperatorCommand extends Command<OperatorFun> {
  OperatorCommand(super.action);
}

class TextObjectCommand extends Command<TextObjectFun> {
  TextObjectCommand(super.action);
}

class MotionCommand extends Command<MotionFun> {
  MotionCommand(super.action);
}

class FindCommand extends Command<FindFun> {
  FindCommand(super.action);
}
