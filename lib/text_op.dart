import 'package:vid/selection.dart';

/// Represents a text operation consisting of an insertion or deletion.
class TextOp {
  final String newText;
  final String prevText;
  final int start;
  final List<Selection> selections; // selections before the operation

  const TextOp({
    required this.newText,
    required this.prevText,
    required this.start,
    required this.selections,
  });

  /// Byte offset where the previous text ends.
  int get endPrev => start + prevText.length;

  /// Byte offset where the new text ends.
  int get endNew => start + newText.length;
}
