import 'package:termio/termio.dart';

/// Base class for input events.
sealed class InputEvent {}

/// A keyboard input event.
class KeyEvent extends InputEvent {
  /// The raw escape sequence or character.
  final String raw;

  /// Logical key name (e.g., 'up', 'down', 'f1', 'home', or the character itself).
  final String key;

  /// Whether Ctrl modifier was pressed.
  final bool ctrl;

  /// Whether Alt/Meta modifier was pressed.
  final bool alt;

  /// Whether Shift modifier was pressed.
  final bool shift;

  KeyEvent({
    required this.raw,
    required this.key,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
  });

  /// Create a simple key event for a single character.
  factory KeyEvent.char(String char) => KeyEvent(raw: char, key: char);

  @override
  String toString() {
    final mods = [
      if (ctrl) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
    ].join('+');
    return 'KeyEvent(${mods.isNotEmpty ? '$mods+' : ''}$key)';
  }
}

/// A mouse input event.
class MouseInputEvent extends InputEvent {
  /// The raw escape sequence.
  final String raw;

  /// The parsed mouse event from termio.
  final MouseEvent event;

  MouseInputEvent({required this.raw, required this.event});

  @override
  String toString() => 'MouseInputEvent($event)';
}
