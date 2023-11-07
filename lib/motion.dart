import 'action_typedefs.dart';

sealed class Motion<T extends Function> {
  final T fn;
  final bool linewise;
  const Motion(this.fn, {this.linewise = false});
}

class NormalMotion extends Motion<MotionFn> {
  const NormalMotion(super.fn, {super.linewise});
}

class FindMotion extends Motion<FindFn> {
  const FindMotion(super.fn, {super.linewise});
}
