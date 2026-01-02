import 'package:termio/termio.dart';

import 'escape_sequences.dart';
import 'input_event.dart';

/// Parses raw terminal input into structured InputEvent objects.
///
/// Handles buffering of incomplete escape sequences and converts
/// raw bytes into KeyEvent and MouseInputEvent objects.
class InputParser {
  /// Buffer for incomplete escape sequences.
  final _buffer = StringBuffer();

  /// Parse input string and return list of complete events.
  ///
  /// Incomplete escape sequences are buffered for the next call.
  List<InputEvent> parse(String input) {
    _buffer.write(input);
    return _extractEvents();
  }

  /// Check if there's buffered incomplete input.
  bool get hasBufferedInput => _buffer.isNotEmpty;

  /// Get the current buffer contents (for debugging).
  String get bufferedInput => _buffer.toString();

  /// Clear the buffer and return any pending input as events.
  ///
  /// Use this when a timeout expires to flush a lone ESC as escape key.
  List<InputEvent> flush() {
    if (_buffer.isEmpty) return [];

    final content = _buffer.toString();
    _buffer.clear();

    // If it's just ESC, return it as escape key
    if (content == Keys.escape) {
      return [KeyEvent(raw: content, key: 'escape')];
    }

    // Otherwise, process whatever we have character by character
    return content.split('').map((c) => _charToEvent(c)).toList();
  }

  /// Extract all complete events from the buffer.
  List<InputEvent> _extractEvents() {
    final events = <InputEvent>[];
    var str = _buffer.toString();
    _buffer.clear();

    var pos = 0;
    while (pos < str.length) {
      // Check for escape sequence at current position
      if (str[pos] == '\x1b') {
        final remaining = str.substring(pos);

        // Check if this could be an incomplete sequence
        if (EscapeSequences.incompleteSequence.hasMatch(remaining)) {
          // Buffer the rest and stop processing
          _buffer.write(remaining);
          break;
        }

        // Try to match a complete sequence
        final match = EscapeSequences.completeSequence.matchAsPrefix(remaining);
        if (match != null) {
          final seq = match.group(0)!;
          events.add(_sequenceToEvent(seq));
          pos += seq.length;
          continue;
        }

        // Lone ESC not followed by sequence start - treat as escape key
        events.add(KeyEvent(raw: '\x1b', key: 'escape'));
        pos++;
        continue;
      }

      // Regular character
      events.add(_charToEvent(str[pos]));
      pos++;
    }

    return events;
  }

  /// Convert a complete escape sequence to an InputEvent.
  InputEvent _sequenceToEvent(String seq) {
    // Check for mouse sequence first
    if (EscapeSequences.mousePattern.hasMatch(seq)) {
      final mouse = MouseEvent.tryParse(seq);
      if (mouse != null) {
        return MouseInputEvent(raw: seq, event: mouse);
      }
    }

    // Check simple sequence lookup
    final simpleKey = EscapeSequences.sequenceToKey[seq];
    if (simpleKey != null) {
      return KeyEvent(raw: seq, key: simpleKey);
    }

    // Parse CSI sequence with potential modifiers
    if (seq.startsWith('\x1b[')) {
      return _parseCsiSequence(seq);
    }

    // Parse SS3 sequence
    if (seq.startsWith('\x1bO')) {
      return _parseSs3Sequence(seq);
    }

    // Unknown sequence - return as raw
    return KeyEvent(raw: seq, key: seq);
  }

  /// Parse a CSI sequence (ESC [ ...).
  KeyEvent _parseCsiSequence(String seq) {
    // Format: ESC [ (n ; m)? final
    // Examples: \x1b[A, \x1b[1;5A, \x1b[5~, \x1b[15;2~

    final content = seq.substring(2); // Remove ESC [
    final finalChar = content[content.length - 1];
    final params = content.substring(0, content.length - 1);

    var ctrl = false;
    var alt = false;
    var shift = false;
    String key;

    if (finalChar == '~') {
      // Tilde sequence: \x1b[5~ or \x1b[5;2~
      final parts = params.split(';');
      final keyCode = int.tryParse(parts[0]) ?? 0;
      key = EscapeSequences.csiTildeToKey[keyCode] ?? seq;

      if (parts.length > 1) {
        final mod = int.tryParse(parts[1]) ?? 1;
        final mods = EscapeSequences.modifierCodes[mod];
        if (mods != null) {
          ctrl = mods.ctrl;
          alt = mods.alt;
          shift = mods.shift;
        }
      }
    } else {
      // Letter final: \x1b[A or \x1b[1;5A
      key = EscapeSequences.csiFinalToKey[finalChar] ?? seq;

      if (params.isNotEmpty) {
        final parts = params.split(';');
        if (parts.length > 1) {
          final mod = int.tryParse(parts[1]) ?? 1;
          final mods = EscapeSequences.modifierCodes[mod];
          if (mods != null) {
            ctrl = mods.ctrl;
            alt = mods.alt;
            shift = mods.shift;
          }
        }
      }
    }

    return KeyEvent(raw: seq, key: key, ctrl: ctrl, alt: alt, shift: shift);
  }

  /// Parse an SS3 sequence (ESC O ...).
  KeyEvent _parseSs3Sequence(String seq) {
    final finalChar = seq[seq.length - 1];
    final key =
        EscapeSequences.csiFinalToKey[finalChar] ??
        EscapeSequences.sequenceToKey[seq] ??
        seq;
    return KeyEvent(raw: seq, key: key);
  }

  /// Convert a single character to a KeyEvent.
  InputEvent _charToEvent(String char) {
    // Check for control characters
    final code = char.codeUnitAt(0);

    if (code < 32) {
      // Control character
      switch (code) {
        case 0:
          return KeyEvent(raw: char, key: 'space', ctrl: true); // Ctrl+Space
        case 9:
          return KeyEvent(raw: char, key: 'tab');
        case 10:
        case 13:
          return KeyEvent(raw: char, key: 'enter');
        case 27:
          return KeyEvent(raw: char, key: 'escape');
        default:
          // Ctrl+letter: code 1-26 = Ctrl+A-Z
          final letter = String.fromCharCode(code + 96); // a=97, so 1+96=97
          return KeyEvent(raw: char, key: letter, ctrl: true);
      }
    }

    if (code == 127) {
      return KeyEvent(raw: char, key: 'backspace');
    }

    // Regular character
    return KeyEvent.char(char);
  }
}
