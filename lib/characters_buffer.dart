import 'package:characters/characters.dart';

class CharactersBuffer {
  var buffer = Characters.empty;

  void write(Characters chars) {
    buffer += chars;
  }

  void writeln(Characters chars) {
    buffer += chars + '\n'.characters;
  }

  void writeString(String string) {
    buffer += string.characters;
  }

  void writelnString(String string) {
    buffer += string.characters + '\n'.characters;
  }

  void clear() {
    buffer = Characters.empty;
  }

  @override
  String toString() {
    return buffer.toString();
  }
}
