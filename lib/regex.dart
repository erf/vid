class Regex {
  static final word = RegExp(r'([\wæøå]+|[^\w\s]+|(?<=\n)\n)');
  static final wordCap = RegExp(r'(\S+|(?<=\n)\n)');
  static final number = RegExp(r'((?:-)?\d+)');
  static final scrollEvents = RegExp('\x1b[O[][A-D]');
  static final nonSpace = RegExp(r'\S');
  static final substitute = RegExp(r's/.+[/]?.*');
  static final paragraph = RegExp(r'(?<=\n)\n|^\w|\n$');
  static final paragraphPrev = RegExp(r'(?<=\n)\n|^\w');
  static final sentence = RegExp(r'(?<=[.!?][ \t\n])\w|\n|^\w|(?<=\n\n).');
}
