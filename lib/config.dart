import 'package:vid/string_ext.dart';

class Config {
  static const messageTime = 2000;
  static const tabWidth = 4;
  static final tabSpaces = List.generate(tabWidth, (_) => ' ').join().ch;
}
