import 'package:vid/editor.dart' as vid;
import 'package:vid/terminal/terminal.dart';

void main(List<String> args) {
  vid.Editor(terminal: Terminal()).init(args);
}
