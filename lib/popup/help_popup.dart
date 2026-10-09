import 'package:termio/termio.dart';

import '../bindings.dart';
import '../command.dart';
import '../editor.dart';
import 'popup.dart';

/// Keybindings help popup, generated from the binding maps in bindings.dart.
class HelpPopup {
  /// Sections shown in the popup, in order.
  static const _sections = <(String, Map<String, Command>)>[
    ('normal', normalCommands),
    ('motion', motionCommands),
    ('operator', operatorCommands),
    ('textobj', textObjectCommands),
    ('visual', visualCommands),
    ('vline', visualLineCommands),
    ('insert', insertBindings),
    ('replace', replaceBindings),
    ('popup', popupBindings),
  ];

  /// Show keybindings popup.
  static void show(Editor editor) {
    editor.showPopup(
      PopupState.create(
        title: 'Keybindings',
        items: items(),
        onSelect: (_) => editor.closePopup(),
        onCancel: () => editor.closePopup(),
      ),
    );
  }

  /// Build popup items, one row per (section, description) with all keys
  /// bound to it merged, e.g. 'Tab, ]s'.
  static List<PopupItem<String>> items() {
    final rows = <(String, List<String>, String)>[];
    void add(String section, String key, String desc) {
      for (final row in rows) {
        if (row.$1 == section && row.$3 == desc) {
          row.$2.add(key);
          return;
        }
      }
      rows.add((section, [key], desc));
    }

    for (final (section, bindings) in _sections) {
      for (final MapEntry(:key, :value) in bindings.entries) {
        final desc = describe(value);
        if (desc != null) add(section, keyName(key), desc);
      }
    }
    for (final MapEntry(:key, :value) in lineEditCommands.entries) {
      if (key.isEmpty) continue;
      add('command', ':$key', humanize(value.type.name));
    }

    final keyWidth = rows
        .map((r) => r.$2.join(', ').length)
        .reduce((a, b) => a > b ? a : b);
    return rows.map((r) {
      final keys = r.$2.join(', ').padRight(keyWidth);
      final label = '${r.$1.padRight(8)}  $keys  ${r.$3}';
      return PopupItem(label: label, value: label);
    }).toList();
  }

  /// Human readable description of [command], or null to hide it.
  static String? describe(Command command) => switch (command) {
    ActionCommand(:final type) => humanize(type.name),
    AliasCommand(:final alias) => 'same as $alias',
    ModeCommand(:final mode) => '${humanize(mode.name)} mode',
    MotionCommand(:final motion) => humanize(motion.type.name),
    OperatorCommand(:final type) => humanize(type.name),
    TextObjectCommand(:final type) => humanize(type.name),
    _ => null,
  };

  /// Readable name for a key sequence, e.g. '\x14' -> 'Ctrl+T'.
  static String keyName(String key) => switch (key) {
    Keys.newline => 'Enter',
    Keys.escape => 'Esc',
    Keys.tab => 'Tab',
    Keys.shiftTab => 'Shift+Tab',
    Keys.backspace => 'Backspace',
    Keys.space => 'Space',
    Keys.arrowUp => 'Up',
    Keys.arrowDown => 'Down',
    Keys.arrowLeft => 'Left',
    Keys.arrowRight => 'Right',
    Keys.home => 'Home',
    Keys.end => 'End',
    _
        when key.length == 1 &&
            key.codeUnitAt(0) >= 1 &&
            key.codeUnitAt(0) <= 26 =>
      'Ctrl+${String.fromCharCode(key.codeUnitAt(0) + 64)}',
    _ => key,
  };

  /// Split a camelCase name into lowercase words, keeping all-caps words,
  /// e.g. 'openThemeSelector' -> 'open theme selector',
  /// 'insideWORD' -> 'inside WORD'.
  static String humanize(String name) => name
      .split(RegExp(r'(?<=[a-z])(?=[A-Z])'))
      .map((w) => w == w.toUpperCase() && w.length > 1 ? w : w.toLowerCase())
      .join(' ');
}
