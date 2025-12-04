// Range of byte offsets in the text
class Range {
  final int start;
  final int end;

  const Range(this.start, this.end);

  // make sure start is before end
  Range get norm {
    if (start <= end) {
      return this;
    }
    return Range(end, start);
  }
}
