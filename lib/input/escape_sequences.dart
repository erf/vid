import 'package:termio/termio.dart';

/// Centralized definitions for terminal escape sequences.
class EscapeSequences {
  EscapeSequences._();

  // ---------------------------------------------------------------------------
  // Regex patterns for matching escape sequences
  // ---------------------------------------------------------------------------

  /// CSI sequences: ESC [ (params) (intermediate) final
  /// Examples: \x1b[A (up), \x1b[5~ (pgup), \x1b[1;5A (ctrl+up)
  static final csiPattern = RegExp(r'\x1b\[[\d;]*[A-Za-z~]');

  /// SS3 sequences: ESC O final
  /// Examples: \x1bOP (F1), \x1bOA (up in application mode)
  static final ss3Pattern = RegExp(r'\x1bO[A-Za-z]');

  /// Mouse SGR extended mode: ESC [ < params M/m
  static final mousePattern = RegExp(r'\x1b\[<[\d;]+[Mm]');

  /// Any complete escape sequence (CSI, SS3, or mouse).
  static final completeSequence = RegExp(
    r'\x1b(?:'
    r'\[[\d;]*[A-Za-z~]|' // CSI
    r'O[A-Za-z]|' // SS3
    r'\[<[\d;]+[Mm]' // Mouse SGR
    r')',
  );

  /// Incomplete escape sequence prefix (needs more input).
  /// Matches sequences that have started but aren't complete yet.
  static final incompleteSequence = RegExp(
    r'\x1b(?:'
    r'\[[\d;]*|' // CSI without final byte
    r'\[<[\d;]*|' // Mouse without final byte
    r'O' // SS3 without final byte
    r')$',
  );

  // ---------------------------------------------------------------------------
  // Sequence to key mapping
  // ---------------------------------------------------------------------------

  /// Maps raw escape sequences to logical key names.
  static const sequenceToKey = <String, String>{
    // Arrow keys (CSI)
    Keys.arrowUp: 'up',
    Keys.arrowDown: 'down',
    Keys.arrowLeft: 'left',
    Keys.arrowRight: 'right',

    // Arrow keys (SS3 - application mode)
    '\x1bOA': 'up',
    '\x1bOB': 'down',
    '\x1bOC': 'right',
    '\x1bOD': 'left',

    // Navigation keys
    Keys.home: 'home',
    Keys.end: 'end',
    Keys.pageUp: 'pageup',
    Keys.pageDown: 'pagedown',
    Keys.insert: 'insert',
    Keys.delete: 'delete',

    // Alternative home/end sequences (some terminals)
    '\x1b[1~': 'home',
    '\x1b[4~': 'end',
    '\x1b[7~': 'home',
    '\x1b[8~': 'end',

    // Function keys (SS3 - F1-F4)
    Keys.f1: 'f1',
    Keys.f2: 'f2',
    Keys.f3: 'f3',
    Keys.f4: 'f4',

    // Function keys (CSI - F5-F12)
    Keys.f5: 'f5',
    Keys.f6: 'f6',
    Keys.f7: 'f7',
    Keys.f8: 'f8',
    Keys.f9: 'f9',
    Keys.f10: 'f10',
    Keys.f11: 'f11',
    Keys.f12: 'f12',

    // Escape key
    Keys.escape: 'escape',
  };

  /// Maps modifier codes to modifier flags.
  /// In CSI sequences like \x1b[1;5A, the 5 means Ctrl.
  /// Format: 1 + (shift ? 1 : 0) + (alt ? 2 : 0) + (ctrl ? 4 : 0)
  static const modifierCodes = <int, ({bool ctrl, bool alt, bool shift})>{
    2: (ctrl: false, alt: false, shift: true), // Shift
    3: (ctrl: false, alt: true, shift: false), // Alt
    4: (ctrl: false, alt: true, shift: true), // Alt+Shift
    5: (ctrl: true, alt: false, shift: false), // Ctrl
    6: (ctrl: true, alt: false, shift: true), // Ctrl+Shift
    7: (ctrl: true, alt: true, shift: false), // Ctrl+Alt
    8: (ctrl: true, alt: true, shift: true), // Ctrl+Alt+Shift
  };

  /// Base key for modified arrow/navigation sequences.
  /// \x1b[1;5A -> modifier=5, final=A -> 'up'
  static const csiFinalToKey = <String, String>{
    'A': 'up',
    'B': 'down',
    'C': 'right',
    'D': 'left',
    'H': 'home',
    'F': 'end',
    'P': 'f1',
    'Q': 'f2',
    'R': 'f3',
    'S': 'f4',
  };

  /// Maps CSI ~ sequences to keys.
  /// \x1b[5~ -> pageup, \x1b[5;5~ -> ctrl+pageup
  static const csiTildeToKey = <int, String>{
    1: 'home',
    2: 'insert',
    3: 'delete',
    4: 'end',
    5: 'pageup',
    6: 'pagedown',
    7: 'home',
    8: 'end',
    11: 'f1',
    12: 'f2',
    13: 'f3',
    14: 'f4',
    15: 'f5',
    17: 'f6',
    18: 'f7',
    19: 'f8',
    20: 'f9',
    21: 'f10',
    23: 'f11',
    24: 'f12',
  };
}
