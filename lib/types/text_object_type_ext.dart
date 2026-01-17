import 'text_object_action_base.dart';
import '../actions/text_object_actions.dart';
import 'text_object_type.dart';

extension TextObjectTypeExt on TextObjectType {
  /// The text object action that implements this text object.
  TextObjectAction get fn => switch (this) {
    .insideParens => const InsideParens(),
    .aroundParens => const AroundParens(),
    .insideBraces => const InsideBraces(),
    .aroundBraces => const AroundBraces(),
    .insideBrackets => const InsideBrackets(),
    .aroundBrackets => const AroundBrackets(),
    .insideAngleBrackets => const InsideAngleBrackets(),
    .aroundAngleBrackets => const AroundAngleBrackets(),
    .insideDoubleQuote => const InsideDoubleQuote(),
    .aroundDoubleQuote => const AroundDoubleQuote(),
    .insideSingleQuote => const InsideSingleQuote(),
    .aroundSingleQuote => const AroundSingleQuote(),
    .insideBacktick => const InsideBacktick(),
    .aroundBacktick => const AroundBacktick(),
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
