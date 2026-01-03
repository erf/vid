import 'package:termio/termio.dart';
import 'package:vid/config_loader.dart';
import 'package:vid/editor.dart' as vid;

void main(List<String> args) {
  final config = ConfigLoader.load();
  vid.Editor(terminal: Terminal(), config: config).init(args);
}
