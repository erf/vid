import 'action_typedefs.dart';

sealed class Action<T extends Function> {
  final T fn;
  const Action(this.fn);
}

class NormalAction extends Action<NormalFn> {
  const NormalAction(super.fn);
}

class OperatorAction extends Action<OperatorFn> {
  const OperatorAction(super.fn);
}

sealed class MotionAction<T extends Function> extends Action<T> {
  final bool linewise;
  final bool? inclusive;
  const MotionAction(super.fn, {this.linewise = false, this.inclusive});
}

class NormalMotionAction extends MotionAction<MotionFn> {
  const NormalMotionAction(super.fn, {super.linewise, super.inclusive});
}

class FindMotionAction extends MotionAction<FindFn> {
  const FindMotionAction(super.fn, {super.linewise, super.inclusive});
}

class InsertAction extends Action<InsertFn> {
  const InsertAction(super.fn);
}

class CommandAction extends Action<CommandFn> {
  const CommandAction(super.fn);
}
