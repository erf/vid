import '../actions/text_object_actions.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';
import 'text_object_type.dart';

extension TextObjectTypeExt on TextObjectType {
  /// The function that implements this text object.
  Range Function(Editor, FileBuffer, int) get fn => switch (this) {
    .insideParens => TextObjectActions.insideParens,
    .aroundParens => TextObjectActions.aroundParens,
    .insideBraces => TextObjectActions.insideBraces,
    .aroundBraces => TextObjectActions.aroundBraces,
    .insideBrackets => TextObjectActions.insideBrackets,
    .aroundBrackets => TextObjectActions.aroundBrackets,
    .insideAngleBrackets => TextObjectActions.insideAngleBrackets,
    .aroundAngleBrackets => TextObjectActions.aroundAngleBrackets,
    .insideDoubleQuote => TextObjectActions.insideDoubleQuote,
    .aroundDoubleQuote => TextObjectActions.aroundDoubleQuote,
    .insideSingleQuote => TextObjectActions.insideSingleQuote,
    .aroundSingleQuote => TextObjectActions.aroundSingleQuote,
    .insideBacktick => TextObjectActions.insideBacktick,
    .aroundBacktick => TextObjectActions.aroundBacktick,
    .insideWord => TextObjectActions.insideWord,
    .aroundWord => TextObjectActions.aroundWord,
    .insideWORD => TextObjectActions.insideWORD,
    .aroundWORD => TextObjectActions.aroundWORD,
    .insideSentence => TextObjectActions.insideSentence,
    .aroundSentence => TextObjectActions.aroundSentence,
    .insideParagraph => TextObjectActions.insideParagraph,
    .aroundParagraph => TextObjectActions.aroundParagraph,
  };
}
