import 'dart:io';

import 'package:characters/characters.dart';

import 'characters_ext.dart';
import 'file_buffer.dart';
import 'position.dart';

extension FileBufferExt on FileBuffer {
  void load(List<String> args) {
    if (args.isEmpty) {
      // always have at least one line with empty string to avoid index out of bounds
      lines = [Characters.empty];
      return;
    }
    filename = args.first;
    final file = File(filename!);
    if (file.existsSync()) {
      lines = file.readAsLinesSync().map(Characters.new).toList();
      if (lines.isEmpty) {
        lines = [Characters.empty];
      }
    }
  }

  void insertText(Characters text, Position pos) {
    final newText = lines[pos.line].replaceRange(pos.char, pos.char, text);
    lines.replaceRange(pos.line, pos.line + 1, newText.split('\n'.characters));
  }
}
