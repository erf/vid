// TextEngine handles text editing operations.
// will handle undo/redo in the future.
class TextEngine {
  static String insert(String text, int index, String str) {
    return text.replaceRange(index, index, str);
  }

  static String replace(String text, int index, int? end, String replacement) {
    return text.replaceRange(index, end, replacement);
  }

  static String replaceChar(String text, int index, String replacement) {
    return replace(text, index, index + 1, replacement);
  }

  static String delete(String text, int index, int? end) {
    return replace(text, index, end, '');
  }
}
