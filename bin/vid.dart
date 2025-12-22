import 'package:termio/termio.dart';
import 'package:vid/editor.dart' as vid;

void main(List<String> args) {
  vid.Editor(terminal: Terminal()).init(args);
}
