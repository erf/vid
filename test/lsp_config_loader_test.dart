import 'package:test/test.dart';
import 'package:vid/features/lsp/lsp_config_loader.dart';
import 'package:vid/features/lsp/lsp_server_config.dart';
import 'package:vid/features/lsp/lsp_server_defaults.dart';

void main() {
  group('LspConfig', () {
    test('withDefaults creates config with all default servers', () {
      final config = LspConfig.withDefaults();

      expect(config.enabled, isTrue);
      expect(config.servers, hasLength(4));
      expect(
        config.servers.keys,
        containsAll(['dart', 'lua', 'clangd', 'swift']),
      );
    });

    test('default constructor creates empty config', () {
      const config = LspConfig();

      expect(config.enabled, isTrue);
      expect(config.servers, isEmpty);
    });
  });

  group('LspConfigLoader', () {
    test('configPaths includes expected locations', () {
      final paths = LspConfigLoader.configPaths;

      expect(paths.length, greaterThanOrEqualTo(1));
      expect(paths.first, endsWith('/lsp_servers.yaml'));
    });

    test('parseConfig parses enabled flag', () {
      final config = LspConfigLoader.parseConfig('''
enabled: false
servers: {}
''');
      expect(config.enabled, isFalse);
      // Should still have defaults merged in
      expect(config.servers, hasLength(4));
    });

    test('parseConfig parses enabled true', () {
      final config = LspConfigLoader.parseConfig('''
enabled: true
''');
      expect(config.enabled, isTrue);
    });

    test('parseConfig defaults enabled to true', () {
      final config = LspConfigLoader.parseConfig('''
servers: {}
''');
      expect(config.enabled, isTrue);
    });

    test('parseConfig parses custom server', () {
      final config = LspConfigLoader.parseConfig('''
servers:
  rust:
    name: "rust-analyzer"
    executable: "rust-analyzer"
    args: []
    extensions: [rs]
    languageIds: [rust]
    projectMarkers: [Cargo.toml]
''');
      expect(config.servers, hasLength(5)); // 4 defaults + 1 custom
      expect(config.servers['rust'], isNotNull);
      expect(config.servers['rust']!.name, equals('rust-analyzer'));
      expect(config.servers['rust']!.extensions, contains('rs'));
    });

    test('parseConfig can disable a default server', () {
      final config = LspConfigLoader.parseConfig('''
servers:
  lua: false
''');
      expect(config.servers, hasLength(3)); // 4 defaults - 1 disabled
      expect(config.servers['lua'], isNull);
      expect(config.servers['dart'], isNotNull);
    });

    test('parseConfig can override a default server', () {
      final config = LspConfigLoader.parseConfig('''
servers:
  dart:
    name: "Custom Dart Server"
    executable: "custom-dart"
    args: ["--custom"]
    extensions: [dart]
    languageIds: [dart]
    projectMarkers: [pubspec.yaml]
''');
      expect(config.servers['dart']!.name, equals('Custom Dart Server'));
      expect(config.servers['dart']!.executable, equals('custom-dart'));
    });

    test('parseConfig returns defaults for invalid yaml', () {
      final config = LspConfigLoader.parseConfig('not: valid: yaml: {{');
      // Should fall back to defaults
      expect(config.enabled, isTrue);
    });

    test('parseConfig returns defaults for non-map yaml', () {
      final config = LspConfigLoader.parseConfig('just a string');
      expect(config.enabled, isTrue);
      expect(config.servers, hasLength(4));
    });
  });

  group('LspServerDefaults', () {
    test('all default servers have required fields', () {
      for (final entry in LspServerDefaults.all.entries) {
        final key = entry.key;
        final config = entry.value;

        expect(
          config.name,
          isNotEmpty,
          reason: '$key: name should not be empty',
        );
        expect(
          config.executable,
          isNotEmpty,
          reason: '$key: executable should not be empty',
        );
        expect(
          config.extensions,
          isNotEmpty,
          reason: '$key: extensions should not be empty',
        );
        expect(
          config.languageIds,
          isNotEmpty,
          reason: '$key: languageIds should not be empty',
        );
      }
    });

    test('dart server has correct configuration', () {
      final dart = LspServerDefaults.dart;

      expect(dart.name, equals('Dart Analysis Server'));
      expect(dart.executable, equals('dart'));
      expect(dart.args, equals(['language-server', '--protocol=lsp']));
      expect(dart.extensions, contains('dart'));
      expect(dart.languageIds, contains('dart'));
      expect(dart.projectMarkers, contains('pubspec.yaml'));
    });

    test('clangd server handles multiple C/C++ extensions', () {
      final clangd = LspServerDefaults.clangd;

      expect(
        clangd.extensions,
        containsAll(['c', 'h', 'cpp', 'hpp', 'cc', 'cxx', 'hxx']),
      );
      expect(clangd.languageIds, containsAll(['c', 'cpp']));
    });

    test('swift server disables semantic tokens', () {
      final swift = LspServerDefaults.swift;

      expect(swift.disableSemanticTokens, isTrue);
    });

    test('fallbackLanguageIds covers common languages', () {
      final fallbacks = LspServerDefaults.fallbackLanguageIds;

      expect(fallbacks['js'], equals('javascript'));
      expect(fallbacks['ts'], equals('typescript'));
      expect(fallbacks['py'], equals('python'));
      expect(fallbacks['rs'], equals('rust'));
      expect(fallbacks['go'], equals('go'));
      expect(fallbacks['md'], equals('markdown'));
    });
  });

  group('LspServerRegistry', () {
    setUp(() {
      LspServerRegistry.reset();
    });

    tearDown(() {
      LspServerRegistry.reset();
    });

    test('initializeWith sets custom config', () {
      final customConfig = LspConfig(
        enabled: true,
        servers: Map.from(defaultLspServers),
      );
      LspServerRegistry.initializeWith(customConfig);

      expect(LspServerRegistry.all, hasLength(4));
    });

    test('enabled reflects config value', () {
      LspServerRegistry.initializeWith(
        LspConfig(enabled: false, servers: Map.from(defaultLspServers)),
      );
      expect(LspServerRegistry.enabled, isFalse);

      LspServerRegistry.reset();
      LspServerRegistry.initializeWith(
        LspConfig(enabled: true, servers: Map.from(defaultLspServers)),
      );
      expect(LspServerRegistry.enabled, isTrue);
    });

    test('getByName returns correct server', () {
      final dart = LspServerRegistry.getByName('dart');

      expect(dart, isNotNull);
      expect(dart!.name, equals('Dart Analysis Server'));
    });

    test('getByName returns null for unknown server', () {
      final unknown = LspServerRegistry.getByName('unknown');

      expect(unknown, isNull);
    });

    test('getForExtension finds server by extension', () {
      final server = LspServerRegistry.getForExtension('dart');

      expect(server, isNotNull);
      expect(server!.name, equals('Dart Analysis Server'));
    });

    test('getForExtension normalizes extension', () {
      final server = LspServerRegistry.getForExtension('.DART');

      expect(server, isNotNull);
      expect(server!.name, equals('Dart Analysis Server'));
    });

    test('getForExtension returns null for unknown extension', () {
      final server = LspServerRegistry.getForExtension('unknown');

      expect(server, isNull);
    });

    test('getForLanguageId finds server by language ID', () {
      final server = LspServerRegistry.getForLanguageId('dart');

      expect(server, isNotNull);
      expect(server!.executable, equals('dart'));
    });

    test('languageIdFromPath returns correct language ID', () {
      expect(LspServerRegistry.languageIdFromPath('main.dart'), equals('dart'));
      expect(LspServerRegistry.languageIdFromPath('test.lua'), equals('lua'));
      expect(LspServerRegistry.languageIdFromPath('main.c'), equals('c'));
      // cpp files return 'c' because clangd's first languageId is 'c'
      expect(LspServerRegistry.languageIdFromPath('main.cpp'), equals('c'));
      expect(
        LspServerRegistry.languageIdFromPath('main.swift'),
        equals('swift'),
      );
    });

    test('languageIdFromPath uses fallbacks for non-LSP languages', () {
      expect(
        LspServerRegistry.languageIdFromPath('script.js'),
        equals('javascript'),
      );
      expect(
        LspServerRegistry.languageIdFromPath('app.ts'),
        equals('typescript'),
      );
      expect(LspServerRegistry.languageIdFromPath('main.py'), equals('python'));
      expect(LspServerRegistry.languageIdFromPath('main.rs'), equals('rust'));
      expect(
        LspServerRegistry.languageIdFromPath('README.md'),
        equals('markdown'),
      );
    });

    test('languageIdFromPath returns plaintext for unknown extensions', () {
      expect(
        LspServerRegistry.languageIdFromPath('file.xyz'),
        equals('plaintext'),
      );
    });

    test('initializeWith with custom servers', () {
      LspServerRegistry.reset();

      final customConfig = LspConfig(
        enabled: false,
        servers: {'test': LspServerDefaults.dart},
      );
      LspServerRegistry.initializeWith(customConfig);

      expect(LspServerRegistry.enabled, isFalse);
      expect(LspServerRegistry.all, hasLength(1));
      expect(LspServerRegistry.getByName('test'), isNotNull);
    });
  });

  group('LspServerConfig', () {
    test('handlesExtension is case-insensitive', () {
      final config = LspServerDefaults.dart;

      expect(config.handlesExtension('dart'), isTrue);
      expect(config.handlesExtension('DART'), isTrue);
      expect(config.handlesExtension('Dart'), isTrue);
    });

    test('handlesLanguageId is case-insensitive', () {
      final config = LspServerDefaults.dart;

      expect(config.handlesLanguageId('dart'), isTrue);
      expect(config.handlesLanguageId('DART'), isTrue);
      expect(config.handlesLanguageId('Dart'), isTrue);
    });

    test('handlesExtension returns false for unhandled extension', () {
      final config = LspServerDefaults.dart;

      expect(config.handlesExtension('lua'), isFalse);
    });
  });
}
