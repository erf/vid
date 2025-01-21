import 'package:vid/editor.dart' as vid;
import 'package:vid/terminal_realdart';

void main(List<String> args) {
  vid.Editor(terminal: TerminalReal()).init(args);
}
