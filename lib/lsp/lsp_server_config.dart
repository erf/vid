import 'dart:io';

/// Configuration for a language server.
class LspServerConfig {
  /// Display name for the language server.
  final String name;

  /// The executable command to start the server.
  final String executable;

  /// Arguments to pass to the executable.
  final List<String> args;

  /// File extensions this server handles.
  final Set<String> extensions;

  /// Language IDs this server handles.
  final Set<String> languageIds;

  /// Marker files that indicate this server should be used for a project.
  /// e.g., 'pubspec.yaml' for Dart, '.luarc.json' for Lua
  final List<String> projectMarkers;

  /// Whether this server supports semantic tokens.
  final bool supportsSemanticTokens;

  /// Whether to prefer built-in syntax highlighting over LSP semantic tokens.
  /// Useful when the built-in highlighter produces better results.
  final bool preferBuiltInHighlighting;

  const LspServerConfig({
    required this.name,
    required this.executable,
    required this.args,
    required this.extensions,
    required this.languageIds,
    required this.projectMarkers,
    this.supportsSemanticTokens = false,
    this.preferBuiltInHighlighting = false,
  });

  /// Check if this server handles a given file extension.
  bool handlesExtension(String ext) => extensions.contains(ext.toLowerCase());

  /// Check if this server handles a given language ID.
  bool handlesLanguageId(String langId) =>
      languageIds.contains(langId.toLowerCase());

  /// Check if the server executable is available on the system.
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('which', [executable]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

/// Registry of available language server configurations.
class LspServerRegistry {
  static final Map<String, LspServerConfig> _servers = {
    'clangd': clangdServer,
    'dart': dartServer,
    'lua': luaServer,
    'swift': swiftServer,
  };

  /// Dart language server configuration.
  static const dartServer = LspServerConfig(
    name: 'Dart Analysis Server',
    executable: 'dart',
    args: ['language-server', '--protocol=lsp'],
    extensions: {'dart'},
    languageIds: {'dart'},
    projectMarkers: ['pubspec.yaml', 'pubspec.lock'],
    supportsSemanticTokens: true,
  );

  /// Lua language server configuration (lua-language-server).
  static const luaServer = LspServerConfig(
    name: 'Lua Language Server',
    executable: 'lua-language-server',
    args: [],
    extensions: {'lua'},
    languageIds: {'lua'},
    projectMarkers: ['.luarc.json', '.luarc.jsonc', '.luacheckrc', 'init.lua'],
    supportsSemanticTokens: true,
  );

  /// C/C++ language server configuration (clangd).
  static const clangdServer = LspServerConfig(
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
    supportsSemanticTokens: true,
  );

  /// Swift language server configuration (SourceKit-LSP).
  static const swiftServer = LspServerConfig(
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
    supportsSemanticTokens: true,
    preferBuiltInHighlighting: true,
  );

  /// Get all registered server configurations.
  static Iterable<LspServerConfig> get all => _servers.values;

  /// Get server configuration by name.
  static LspServerConfig? getByName(String name) => _servers[name];

  /// Get server configuration for a file extension.
  static LspServerConfig? getForExtension(String ext) {
    final normalizedExt = ext.toLowerCase().replaceFirst('.', '');
    for (final server in _servers.values) {
      if (server.handlesExtension(normalizedExt)) {
        return server;
      }
    }
    return null;
  }

  /// Get server configuration for a language ID.
  static LspServerConfig? getForLanguageId(String langId) {
    for (final server in _servers.values) {
      if (server.handlesLanguageId(langId)) {
        return server;
      }
    }
    return null;
  }

  /// Get language ID from file path based on registered server configs.
  /// Falls back to common language mappings for non-LSP languages.
  static String languageIdFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();

    // Check registered LSP servers first
    for (final server in _servers.values) {
      if (server.extensions.contains(ext)) {
        return server.languageIds.first;
      }
    }

    // Fallback for languages without LSP config
    return switch (ext) {
      'js' => 'javascript',
      'ts' => 'typescript',
      'json' => 'json',
      'yaml' || 'yml' => 'yaml',
      'md' => 'markdown',
      'html' => 'html',
      'css' => 'css',
      'py' => 'python',
      'rs' => 'rust',
      'go' => 'go',
      'java' => 'java',
      'kt' => 'kotlin',
      _ => 'plaintext',
    };
  }

  /// Detect which server to use based on project files in a directory.
  static LspServerConfig? detectForProject(String rootPath) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return null;

    for (final server in _servers.values) {
      if (_hasProjectMarker(dir, rootPath, server.projectMarkers)) {
        return server;
      }
    }
    return null;
  }

  /// Get all servers that might be relevant for files in a directory.
  static List<LspServerConfig> detectAllForProject(String rootPath) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return [];

    final results = <LspServerConfig>[];
    for (final server in _servers.values) {
      if (_hasProjectMarker(dir, rootPath, server.projectMarkers)) {
        results.add(server);
      }
    }
    return results;
  }

  /// Check if any project marker exists in the directory.
  /// Supports glob patterns like '*.xcworkspace'.
  static bool _hasProjectMarker(
    Directory dir,
    String rootPath,
    List<String> markers,
  ) {
    for (final marker in markers) {
      if (marker.contains('*')) {
        // Glob pattern - check directory entries
        final suffix = marker.replaceFirst('*', '');
        try {
          for (final entity in dir.listSync()) {
            final name = entity.path.split('/').last;
            if (name.endsWith(suffix)) {
              return true;
            }
          }
        } catch (_) {
          // Ignore permission errors etc.
        }
      } else {
        // Exact file match
        if (File('$rootPath/$marker').existsSync()) {
          return true;
        }
      }
    }
    return false;
  }
}
