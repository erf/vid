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
