import 'package:test/test.dart';
import 'package:vid/config.dart';

void main() {
  group('Config.fromMap', () {
    group('_parseStringSet', () {
      test('parses YAML list', () {
        final config = Config.fromMap({
          'fileBrowserExcludeDirs': ['.git', 'node_modules', 'build'],
        });
        expect(config.fileBrowserExcludeDirs, {
          '.git',
          'node_modules',
          'build',
        });
      });

      test('parses empty YAML list', () {
        final config = Config.fromMap({'formatOnSaveLanguages': []});
        expect(config.formatOnSaveLanguages, <String>{});
      });

      test('uses default when field not provided', () {
        final config = Config.fromMap({});
        expect(config.fileBrowserExcludeDirs, Config.defaultExcludeDirs);
        expect(config.formatOnSaveLanguages, <String>{});
      });

      test('uses default when field is null', () {
        final config = Config.fromMap({'fileBrowserExcludeDirs': null});
        expect(config.fileBrowserExcludeDirs, Config.defaultExcludeDirs);
      });

      test('uses default when field is invalid type', () {
        final config = Config.fromMap({'fileBrowserExcludeDirs': 'not a list'});
        expect(config.fileBrowserExcludeDirs, Config.defaultExcludeDirs);
      });

      test('handles mixed list types', () {
        final config = Config.fromMap({
          'formatOnSaveLanguages': ['dart', 123, true, 'python'],
        });
        expect(config.formatOnSaveLanguages, {'dart', '123', 'true', 'python'});
      });
    });
  });
}
