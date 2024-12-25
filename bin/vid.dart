import 'package:vid/editor.dart' as vid;
import 'package:vid/terminal.dart';

void main(List<String> args) {
  vid.Editor(term: TerminalImpl()).init(args);
}
