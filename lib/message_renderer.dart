import 'package:termio/termio.dart';

import 'highlighting/highlighter.dart';
import 'message.dart';

/// Renders transient messages (info/error) just above the status bar.
class MessageRenderer {
  final TerminalBase terminal;
  final Highlighter highlighter;

  MessageRenderer({required this.terminal, required this.highlighter});

  /// Maximum number of message lines to display.
  static const int maxLines = 5;

  /// Draw [message] above the status bar.
  void draw(StringBuffer buffer, Message message) {
    final text = message.text;
    final contentWidth = terminal.width - 2; // Leave space for padding

    // Split text into lines, respecting embedded newlines and wrapping long lines
    final lines = <String>[];
    for (final paragraph in text.split('\n')) {
      if (lines.length >= maxLines) break;
      var remaining = paragraph;
      while (remaining.isNotEmpty && lines.length < maxLines) {
        if (remaining.length <= contentWidth) {
          lines.add(remaining);
          break;
        }
        // Find a good break point (prefer space)
        var breakAt = contentWidth;
        for (var i = contentWidth; i > contentWidth ~/ 2; i--) {
          if (remaining[i] == ' ') {
            breakAt = i;
            break;
          }
        }
        lines.add(remaining.substring(0, breakAt));
        remaining = remaining.substring(breakAt).trimLeft();
      }
    }

    final msgRow = terminal.height - lines.length;

    switch (message.type) {
      case MessageType.info:
        buffer.write(Ansi.fg(Color.green));
      case MessageType.error:
        buffer.write(Ansi.fg(Color.red));
    }
    buffer.write(Ansi.inverse(true));

    for (var i = 0; i < lines.length; i++) {
      buffer.write(Ansi.cursor(x: 1, y: msgRow + i));
      buffer.write(' ${lines[i]} ');
    }

    buffer.write(Ansi.inverse(false));
    highlighter.theme.resetCode(buffer);
  }
}
