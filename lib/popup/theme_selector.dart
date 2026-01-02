import '../editor.dart';
import '../highlighting/theme.dart';
import 'popup.dart';

/// Theme selector popup for switching between themes.
class ThemeSelector {
  /// Show theme selector popup.
  static void show(Editor editor) {
    final items = _listThemes(editor);

    // Pre-select current theme
    final selectedIndex = editor.config.syntaxTheme.index;

    editor.showPopup(
      PopupState.create(
        title: 'Themes',
        items: items,
        onSelect: (item) => _onSelect(editor, item as PopupItem<ThemeType>),
        onHighlight: (item) =>
            _onHighlight(editor, item as PopupItem<ThemeType>),
        onCancel: () => editor.closePopup(),
      ).copyWith(selectedIndex: selectedIndex),
    );
  }

  /// List themes as popup items.
  static List<PopupItem<ThemeType>> _listThemes(Editor editor) {
    return ThemeType.values.map((type) {
      return PopupItem<ThemeType>(label: type.theme.name, value: type);
    }).toList();
  }

  static void _onSelect(Editor editor, PopupItem<ThemeType> item) {
    editor.setTheme(item.value);
    editor.closePopup();
    editor.draw();
  }

  static void _onHighlight(Editor editor, PopupItem<ThemeType> item) {
    editor.setTheme(item.value);
    editor.draw();
  }
}
