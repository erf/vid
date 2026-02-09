import '../actions/motion_actions.dart';
import '../regex.dart';
import '../types/motion_action_base.dart';
import 'motion_type.dart';

extension MotionTypeExt on MotionType {
  /// The action that implements this motion
  MotionAction get fn => switch (this) {
    .charNext => const CharNext(),
    .charPrev => const CharPrev(),
    .lineDown => const LineDown(),
    .lineUp => const LineUp(),
    .lineStart => const LineStart(),
    .lineEnd => const LineEnd(),
    .firstNonBlank => const FirstNonBlank(),
    .wordNext => WordNextMotion(Regex.word),
    .wordPrev => WordPrevMotion(Regex.word),
    .wordEnd => WordEndMotion(Regex.word),
    .wordEndPrev => WordEndPrevMotion(Regex.word),
    .wordCapNext => WordNextMotion(Regex.wordCap),
    .wordCapPrev => WordPrevMotion(Regex.wordCap),
    .wordCapEnd => WordEndMotion(Regex.wordCap),
    .wordCapEndPrev => WordEndPrevMotion(Regex.wordCap),
    .fileStart => const FileStart(),
    .fileEnd => const FileEnd(),
    .findNextChar => const FindNextChar(),
    .findPrevChar => const FindPrevChar(),
    .findTillNextChar => const FindTillNextChar(),
    .findTillPrevChar => const FindTillPrevChar(),
    .paragraphNext => const ParagraphNext(),
    .paragraphPrev => const ParagraphPrev(),
    .sentenceNext => const SentenceNext(),
    .sentencePrev => const SentencePrev(),
    .sameWordNext => const SameWordMotion(forward: true),
    .sameWordPrev => const SameWordMotion(forward: false),
    .searchNext => const SearchNext(),
    .searchPrev => const SearchPrev(),
    .matchBracket => const MatchBracket(),
    .linewise => const Linewise(),
  };

  /// The reversed motion type, or null if not reversible
  MotionType? get reversed => switch (this) {
    .charNext => .charPrev,
    .charPrev => .charNext,
    .lineDown => .lineUp,
    .lineUp => .lineDown,
    .wordNext => .wordPrev,
    .wordPrev => .wordNext,
    .wordEnd => .wordEndPrev,
    .wordEndPrev => .wordEnd,
    .wordCapNext => .wordCapPrev,
    .wordCapPrev => .wordCapNext,
    .wordCapEnd => .wordCapEndPrev,
    .wordCapEndPrev => .wordCapEnd,
    .fileStart => .fileEnd,
    .fileEnd => .fileStart,
    .findNextChar => .findPrevChar,
    .findPrevChar => .findNextChar,
    .findTillNextChar => .findTillPrevChar,
    .findTillPrevChar => .findTillNextChar,
    .paragraphNext => .paragraphPrev,
    .paragraphPrev => .paragraphNext,
    .sentenceNext => .sentencePrev,
    .sentencePrev => .sentenceNext,
    .sameWordNext => .sameWordPrev,
    .sameWordPrev => .sameWordNext,
    .searchNext => .searchPrev,
    .searchPrev => .searchNext,
    _ => null,
  };
}
