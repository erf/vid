/// Types of motions - used for identification and reversing.
enum MotionType {
  // Character motions
  charNext,
  charPrev,

  // Line motions
  lineDown,
  lineUp,
  lineStart,
  lineEnd,
  firstNonBlank,

  // Word motions
  wordNext,
  wordPrev,
  wordEnd,
  wordEndPrev,
  wordCapNext,
  wordCapPrev,
  wordCapEnd,
  wordCapEndPrev,

  // File motions
  fileStart,
  fileEnd,

  // Find char motions (f/F/t/T)
  findNextChar,
  findPrevChar,
  findTillNextChar,
  findTillPrevChar,

  // Paragraph/sentence motions
  paragraphNext,
  paragraphPrev,
  sentenceNext,
  sentencePrev,

  // Same word motions (* / #)
  sameWordNext,
  sameWordPrev,

  // Search motions (n/N)
  searchNext,
  searchPrev,

  // Match bracket (%)
  matchBracket,

  // Special - for dd/yy/cc
  linewise,
}
