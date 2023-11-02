import 'action_typedefs.dart';

sealed class Command<T extends Function> {
  T action;

  Command(this.action);
}

class InsertCommand extends Command<InsertFn> {
  InsertCommand(super.action);
}

class NormalCommand extends Command<NormalFn> {
  NormalCommand(super.action);
}

class OperatorCommand extends Command<OperatorFn> {
  OperatorCommand(super.action);
}

class MotionCommand extends Command<MotionFn> {
  MotionCommand(super.action);
}

class FindCommand extends Command<FindFn> {
  FindCommand(super.action);
}
