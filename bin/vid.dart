import 'package:vid/editor.dart' as vid;
import 'package:vid/terminal_impl.dart';

void main(List<String> args) {
  vid.Editor(terminal: TerminalImpl()).init(args);
}
