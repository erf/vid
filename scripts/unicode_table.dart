import 'dart:io';
import 'dart:typed_data';

import 'package:vid/unicode_width_table.dart';

import 'gen_east_asian_width.dart';
import 'gen_emoji_data.dart';
import 'gen_emoji_sequences.dart';

Future<void> populateWidthTable(UnicodeWidthTable table) async {
  // Parse EastAsianWidth.txt
  final eastAsianWidthParser = EastAsianWidthParser();
  await eastAsianWidthParser.load();
  for (var range in eastAsianWidthParser.wideRanges.ranges) {
    for (var codePoint = range.start; codePoint <= range.end; codePoint++) {
      table.setWidth(codePoint, 2);
    }
  }

  // Parse emoji-data.txt
  final emojiDataParser = EmojiDataParser();
  await emojiDataParser.load();
  for (var range in emojiDataParser.emojiRanges.ranges) {
    for (var codePoint = range.start; codePoint <= range.end; codePoint++) {
      table.setWidth(codePoint, 2);
    }
  }

  // Parse emoji-sequences.txt (for multi-codepoint sequences)
  final emojiSequencesParser = EmojiSequencesParser();
  await emojiSequencesParser.load();
  for (var sequence in emojiSequencesParser.emojiSequences) {
    // Multi-codepoint sequences require special handling
    // They can't fit directly into the 3-stage table, but this can be handled at runtime.
    // For now, store a flag or handle them separately.
  }
}

Future<void> saveTableToFile(UnicodeWidthTable table, String path) async {
  final buffer = BytesBuilder();
  buffer.add(table.stage1.expand((x) => [x >> 8, x & 0xFF]).toList());
  for (var stage2Entry in table.stage2) {
    buffer.add(stage2Entry.expand((x) => [x >> 8, x & 0xFF]).toList());
  }
  for (var stage3Entry in table.stage3) {
    buffer.add(stage3Entry);
  }
  await File(path).writeAsBytes(buffer.toBytes());
}
