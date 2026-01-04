/// Yank buffer with linewise information
class YankBuffer {
  final String text;
  final bool linewise;

  const YankBuffer(this.text, {this.linewise = false});
}
