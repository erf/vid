import 'package:vid/string_ext.dart';

class Config {
  static const tabWidth = 4;
  static final tabSpaces =
      List.generate(Config.tabWidth, (_) => ' ', growable: false).join().ch;
}
