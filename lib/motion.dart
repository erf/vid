import 'action_typedefs.dart';

sealed class Motion<T extends Function> {
  final T fn;
  final bool linewise;
  final bool? inclusive;
  const Motion(this.fn, {this.linewise = false, this.inclusive});
}

class NormalMotion extends Motion<MotionFn> {
  const NormalMotion(super.fn, {super.linewise, super.inclusive});
}

class FindMotion extends Motion<FindFn> {
  const FindMotion(super.fn, {super.linewise, super.inclusive});
}
