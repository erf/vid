import '../actions/text_objects.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';

/// Types of text objects - used for keybindings (di(, da{, ciw, etc.).
enum TextObjectType {
  // Parentheses
  insideParens,
  aroundParens,

  // Braces
  insideBraces,
  aroundBraces,

  // Brackets
  insideBrackets,
  aroundBrackets,

  // Angle brackets
  insideAngleBrackets,
  aroundAngleBrackets,

  // Double quotes
  insideDoubleQuote,
  aroundDoubleQuote,

  // Single quotes
  insideSingleQuote,
  aroundSingleQuote,

  // Backticks
  insideBacktick,
  aroundBacktick,

  // Word
  insideWord,
  aroundWord,

  // WORD (space-separated)
  insideWORD,
  aroundWORD,

  // Sentence
  insideSentence,
  aroundSentence,

  // Paragraph
  insideParagraph,
  aroundParagraph,
}

extension TextObjectTypeExt on TextObjectType {
  /// The function that implements this text object.
  Range Function(Editor, FileBuffer, int) get fn => switch (this) {
    .insideParens => TextObjects.insideParens,
    .aroundParens => TextObjects.aroundParens,
    .insideBraces => TextObjects.insideBraces,
    .aroundBraces => TextObjects.aroundBraces,
    .insideBrackets => TextObjects.insideBrackets,
    .aroundBrackets => TextObjects.aroundBrackets,
    .insideAngleBrackets => TextObjects.insideAngleBrackets,
    .aroundAngleBrackets => TextObjects.aroundAngleBrackets,
    .insideDoubleQuote => TextObjects.insideDoubleQuote,
    .aroundDoubleQuote => TextObjects.aroundDoubleQuote,
    .insideSingleQuote => TextObjects.insideSingleQuote,
    .aroundSingleQuote => TextObjects.aroundSingleQuote,
    .insideBacktick => TextObjects.insideBacktick,
    .aroundBacktick => TextObjects.aroundBacktick,
    .insideWord => TextObjects.insideWord,
    .aroundWord => TextObjects.aroundWord,
    .insideWORD => TextObjects.insideWORD,
    .aroundWORD => TextObjects.aroundWORD,
    .insideSentence => TextObjects.insideSentence,
    .aroundSentence => TextObjects.aroundSentence,
    .insideParagraph => TextObjects.insideParagraph,
    .aroundParagraph => TextObjects.aroundParagraph,
  };
}
