import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('make sure we convert tabs to spaces', () {
    expect('\t'.tabsToSpaces, '    ');
    expect('\t\t'.tabsToSpaces, '        ');
    expect('a\tb'.tabsToSpaces, 'a    b');
  });
}
