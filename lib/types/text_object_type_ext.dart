import 'text_object_action_base.dart';
import '../actions/text_object_actions.dart';
import 'text_object_type.dart';

extension TextObjectTypeExt on TextObjectType {
  /// The text object action that implements this text object.
  TextObjectAction get fn => switch (this) {
    .insideParens => const InsidePair('(', ')'),
    .aroundParens => const AroundPair('(', ')'),
    .insideBraces => const InsidePair('{', '}'),
    .aroundBraces => const AroundPair('{', '}'),
    .insideBrackets => const InsidePair('[', ']'),
    .aroundBrackets => const AroundPair('[', ']'),
    .insideAngleBrackets => const InsidePair('<', '>'),
    .aroundAngleBrackets => const AroundPair('<', '>'),
    .insideDoubleQuote => const InsideQuote('"'),
    .aroundDoubleQuote => const AroundQuote('"'),
    .insideSingleQuote => const InsideQuote("'"),
    .aroundSingleQuote => const AroundQuote("'"),
    .insideBacktick => const InsideQuote('`'),
    .aroundBacktick => const AroundQuote('`'),
    .insideWord => const InsideWord(),
    .aroundWord => const AroundWord(),
    .insideWORD => const InsideWORD(),
    .aroundWORD => const AroundWORD(),
    .insideSentence => const InsideSentence(),
    .aroundSentence => const AroundSentence(),
    .insideParagraph => const InsideParagraph(),
    .aroundParagraph => const AroundParagraph(),
  };
}
