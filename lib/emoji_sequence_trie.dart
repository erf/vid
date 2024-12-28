import 'package:vid/emoji_sequences.dart';

class TrieNode {
  final Map<int, TrieNode> children = {};
  bool isEndOfSequence = false;
}

class EmojiSequenceTrie {
  final TrieNode root = TrieNode();

  EmojiSequenceTrie(List<List<int>> emojiSequences) {
    populateTrieFromList(emojiSequences);
  }

  void populateTrieFromList(List<List<int>> emojiSequences) {
    for (final sequence in emojiSequences) {
      insert(sequence);
    }
  }

  // Insert a sequence of code points into the trie
  void insert(List<int> sequence) {
    TrieNode current = root;
    for (final codePoint in sequence) {
      current = current.children.putIfAbsent(codePoint, () => TrieNode());
    }
    current.isEndOfSequence = true;
  }

  // Check if a sequence exists in the trie
  bool matches(List<int> sequence) {
    TrieNode? current = root;
    for (final codePoint in sequence) {
      current = current?.children[codePoint];
      if (current == null) return false;
    }
    return current?.isEndOfSequence ?? false;
  }

  // Find the longest matching sequence
  List<int>? findLongestMatch(List<int> input) {
    TrieNode? current = root;
    List<int>? longestMatch;
    final List<int> buffer = <int>[];

    for (final codePoint in input) {
      current = current?.children[codePoint];
      if (current == null) break;

      buffer.add(codePoint);
      if (current.isEndOfSequence) {
        longestMatch = List.from(buffer);
      }
    }

    return longestMatch;
  }
}

final emojiSequenceTrie = EmojiSequenceTrie(emojiSequences);
