class Regex {
  static final word = RegExp(r'(\w+|[^\w\s]+|(?<=\n)\n)');
  static final wordCap = RegExp(r'(\S+|(?<=\n)\n)');
  static final number = RegExp(r'((?:-)?\d+)');
  static final scrollEvents = RegExp('\x1b([O[])[A-D]');
  static final nonSpace = RegExp(r'\S');
}
