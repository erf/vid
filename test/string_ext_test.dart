import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('make sure we convert tabs to spaces', () {
    expect('\t'.tabsToSpaces(4), '    ');
    expect('\t\t'.tabsToSpaces(4), '        ');
    expect('a\tb'.tabsToSpaces(4), 'a    b');
    expect('a\tb'.tabsToSpaces(2), 'a  b');
  });
}
