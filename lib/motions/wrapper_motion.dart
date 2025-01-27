import 'package:vid/file_buffer.dart';
import 'package:vid/motions/motion.dart';
import 'package:vid/position.dart';

class WrapperMotion extends Motion {
  const WrapperMotion(this.func, {super.inclusive, super.linewise});

  final Position Function(FileBuffer f, Position p) func;

  @override
  Position run(FileBuffer f, Position p, {bool op = false}) {
    return func(f, p);
  }
}
