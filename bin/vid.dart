import 'package:termio/termio.dart';
import 'package:vid/config_loader.dart';
import 'package:vid/editor.dart' as vid;

Future<void> main(List<String> args) async {
  // Load editor config and LSP config in parallel for faster startup
  final config = await ConfigLoader.loadAllAsync();
  vid.Editor(terminal: Terminal(), config: config).init(args);
}
