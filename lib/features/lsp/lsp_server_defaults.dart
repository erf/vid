import 'lsp_server_config.dart';

/// Default LSP server configurations.
///
/// These are used as fallbacks when no user configuration is found,
/// or when the user config file fails to load.
class LspServerDefaults {
  /// Dart language server configuration.
  static const dart = LspServerConfig(
    name: 'Dart Analysis Server',
    executable: 'dart',
    args: ['language-server', '--protocol=lsp'],
    extensions: {'dart'},
    languageIds: {'dart'},
    projectMarkers: ['pubspec.yaml', 'pubspec.lock'],
  );

  /// Lua language server configuration (lua-language-server).
  static const lua = LspServerConfig(
    name: 'Lua Language Server',
    executable: 'lua-language-server',
    args: [],
    extensions: {'lua'},
    languageIds: {'lua'},
    projectMarkers: ['.luarc.json', '.luarc.jsonc', '.luacheckrc', 'init.lua'],
  );

  /// C/C++ language server configuration (clangd).
  static const clangd = LspServerConfig(
    name: 'clangd',
    executable: 'clangd',
    args: ['--background-index'],
    extensions: {'c', 'h', 'cc', 'cpp', 'cxx', 'hpp', 'hxx'},
    languageIds: {'c', 'cpp'},
    projectMarkers: [
      'compile_commands.json',
      'compile_flags.txt',
      '.clangd',
      'CMakeLists.txt',
      'Makefile',
    ],
  );

  /// Swift language server configuration (SourceKit-LSP).
  static const swift = LspServerConfig(
    name: 'SourceKit-LSP',
    executable: 'sourcekit-lsp',
    args: [],
    extensions: {'swift'},
    languageIds: {'swift'},
    projectMarkers: [
      'Package.swift',
      'Podfile',
      '*.xcworkspace',
      '*.xcodeproj',
    ],
    disableSemanticTokens: true,
  );

  /// TypeScript/JavaScript language server configuration.
  /// Uses typescript-language-server which wraps tsserver.
  static const typescript = LspServerConfig(
    name: 'TypeScript Language Server',
    executable: 'typescript-language-server',
    args: ['--stdio'],
    extensions: {'ts', 'tsx', 'js', 'jsx', 'mjs', 'cjs', 'mts', 'cts'},
    languageIds: {
      'typescript',
      'typescriptreact',
      'javascript',
      'javascriptreact',
    },
    projectMarkers: ['tsconfig.json', 'jsconfig.json', 'package.json'],
  );

  /// All default server configurations, keyed by identifier.
  static const Map<String, LspServerConfig> all = {
    'dart': dart,
    'lua': lua,
    'clangd': clangd,
    'swift': swift,
    'typescript': typescript,
  };

  /// Fallback language ID mappings for extensions without LSP config.
  static const Map<String, String> fallbackLanguageIds = {
    'js': 'javascript',
    'jsx': 'javascriptreact',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescriptreact',
    'mts': 'typescript',
    'cts': 'typescript',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'md': 'markdown',
    'html': 'html',
    'css': 'css',
    'py': 'python',
    'rs': 'rust',
    'go': 'go',
    'java': 'java',
    'kt': 'kotlin',
  };
}

/// Top-level constant for easy access to default LSP server configurations.
const defaultLspServers = LspServerDefaults.all;
