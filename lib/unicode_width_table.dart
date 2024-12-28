class UnicodeWidthTable {
  static const int stage1BlockSize = 512; // 2^9
  static const int stage2BlockSize = 64; // 2^6
  static const int unicodeMax = 0x10FFFF;

  final List<int> stage1 = List.filled((unicodeMax >> 9) + 1, -1);
  final List<List<int>> stage2 = [];
  final List<List<int>> stage3 = [];

  void setWidth(int codePoint, int width) {
    final stage1Index = codePoint >> 9; // Top 9 bits
    final stage2Index = (codePoint >> 6) & 0x7; // Middle 6 bits
    final stage3Index = codePoint & 0x3F; // Bottom 6 bits

    if (stage1[stage1Index] == -1) {
      stage1[stage1Index] = stage2.length;
      stage2.add(List.filled(8, -1)); // Stage 2 has 8 entries per block
    }

    if (stage2[stage1[stage1Index]][stage2Index] == -1) {
      stage2[stage1[stage1Index]][stage2Index] = stage3.length;
      stage3.add(List.filled(64, 1)); // Default width is 1
    }

    stage3[stage2[stage1[stage1Index]][stage2Index]][stage3Index] = width;
  }

  int getWidth(int codePoint) {
    final stage1Index = codePoint >> 9; // Top 9 bits
    final stage2Index = (codePoint >> 6) & 0x7; // Middle 6 bits
    final stage3Index = codePoint & 0x3F; // Bottom 6 bits

    final stage2TableIndex = stage1[stage1Index];
    if (stage2TableIndex == -1) return 1;

    final stage3TableIndex = stage2[stage2TableIndex][stage2Index];
    if (stage3TableIndex == -1) return 1;

    return stage3[stage3TableIndex][stage3Index];
  }
}
