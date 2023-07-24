import 'package:characters/characters.dart';
import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('CharacterRange methods', () {
    final source = 'abc def ghi';
    final range = CharacterRange(source);
    expect(range.current, '');
    range.moveNext(7);
    expect(range.current, 'abc def');
    range.collapseToLast('def'.ch);
    expect(range.current, 'def');
    range.expandBackAll();
    expect(range.current, 'abc def');
    range.dropFirst(4);
    expect(range.current, 'def');
    expect(range.source.string, 'abc def ghi');
    range.dropLast(3);
    expect(range.current, '');
    range.moveBack();
    range.moveBackAll();
    expect(range.current, 'abc');
    range.expandAll();
    expect(range.current, 'abc def ghi');
    range.moveBackAll();
    expect(range.current, '');
    range.moveTo('d'.ch);
    expect(range.current, 'd');
    expect(range.stringBeforeLength, 4);
  });
}
