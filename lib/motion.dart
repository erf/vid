import 'action_typedefs.dart';

class Motion {
  final MotionFn fn;
  final bool linewise;
  const Motion(this.fn, {this.linewise = false});
}
