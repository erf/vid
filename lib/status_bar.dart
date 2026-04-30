import 'package:termio/termio.dart';

import 'config.dart';
import 'file_buffer/file_buffer.dart';
import 'highlighting/highlighter.dart';

/// Renders the bottom status bar and the command/search input line.
class StatusBar {
  final TerminalBase terminal;
  final Highlighter highlighter;

  StatusBar({required this.terminal, required this.highlighter});

  /// Draw the command/search input line at the bottom of the screen.
  void drawLineEdit(StringBuffer buffer, FileBuffer file) {
    final String lineEdit = file.input.lineEdit;

    buffer.write(Ansi.cursor(x: 1, y: terminal.height));
    if (file.mode == .search) {
      buffer.write('/$lineEdit ');
    } else if (file.mode == .searchBackward) {
      buffer.write('?$lineEdit ');
    } else {
      buffer.write(':$lineEdit ');
    }
    int cursor = lineEdit.length + 2;
    buffer.write(Ansi.cursorStyle(.steadyBar));
    buffer.write(Ansi.cursor(x: cursor, y: terminal.height));
  }

  /// Draw the status bar at the bottom of the screen.
  void draw(
    StringBuffer buffer,
    FileBuffer file,
    Config config,
    int cursorLine,
    int bufferIndex,
    int bufferCount,
    int diagnosticCount,
  ) {
    buffer.write(Ansi.inverse(true));
    buffer.write(Ansi.cursor(x: 1, y: terminal.height));

    int cursorCol = file.columnInLine(file.cursor);
    String mode = file.mode.label;
    // Show selection count when multiple selections exist
    if (file.selections.length > 1) {
      mode = '$mode[${file.selections.length}]';
    }
    String path = file.relativePath ?? '[No Name]';
    String modified = file.modified ? '*' : '';
    String pathWithMod = '$path$modified';
    String wrap = config.wrapSymbol;

    // Build left side with special formatting for buffer indicator and diagnostics
    final leftParts = <String>[mode, pathWithMod];
    if (wrap.isNotEmpty) leftParts.add(wrap);
    String left = leftParts.join(' ');

    // Calculate extra parts that need special formatting
    // After Ansi.reset(), we must restore theme colors before continuing
    final theme = highlighter.theme;
    final themeRestore = '${theme.background ?? ''}${theme.foreground ?? ''}';

    String bufferPart = '';
    if (bufferCount > 1) {
      bufferPart =
          ' ${Ansi.dim()}${bufferIndex + 1}/$bufferCount${Ansi.reset()}$themeRestore${Ansi.inverse(true)}';
    }
    String diagPart = '';
    if (diagnosticCount > 0) {
      diagPart =
          ' ${Ansi.fg(Color.red)}!$diagnosticCount${Ansi.reset()}$themeRestore${Ansi.inverse(true)}';
    }

    // Calculate visible lengths (without ANSI codes)
    int bufferVisibleLen = bufferCount > 1
        ? ' ${bufferIndex + 1}/$bufferCount'.length
        : 0;
    int diagVisibleLen = diagnosticCount > 0 ? ' !$diagnosticCount'.length : 0;

    String right = ' ${cursorLine + 1}, ${cursorCol + 1} ';
    int padLeft =
        terminal.width - left.length - bufferVisibleLen - diagVisibleLen - 2;
    String padding = right.padLeft(padLeft);

    buffer.write(' $left$bufferPart$diagPart $padding');
    buffer.write(Ansi.inverse(false));
  }
}
