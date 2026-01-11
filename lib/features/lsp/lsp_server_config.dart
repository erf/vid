import 'dart:io';

import 'lsp_config_loader.dart';
import 'lsp_server_defaults.dart';

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

  /// Whether to disable LSP semantic tokens for this server.
  /// Use when the built-in regex highlighter produces better results.
  final bool disableSemanticTokens;

  const LspServerConfig({
    required this.name,
    required this.executable,
    required this.args,
    required this.extensions,
    required this.languageIds,
    required this.projectMarkers,
    this.disableSemanticTokens = false,
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
///
/// This registry can be initialized with configurations loaded from a YAML file,
/// or falls back to hardcoded defaults.
class LspServerRegistry {
  /// Singleton instance, lazily initialized.
  static LspServerRegistry? _instance;

  /// The loaded LSP configuration.
  final LspConfig _config;

  /// Private constructor.
  LspServerRegistry._(this._config);

  /// Gets the singleton instance, initializing with defaults if needed.
  /// For async initialization, call [initializeAsync] first.
  static LspServerRegistry get instance {
    _instance ??= LspServerRegistry._(LspConfigLoader.load());
    return _instance!;
  }

  /// Whether LSP support is enabled globally.
  static bool get enabled => instance._config.enabled;

  /// Initializes the registry synchronously.
  /// Call this at startup to load configuration.
  static void initialize() {
    _instance ??= LspServerRegistry._(LspConfigLoader.load());
  }

  /// Initializes the registry asynchronously.
  /// Preferred for startup to avoid blocking.
  static Future<void> initializeAsync() async {
    if (_instance == null) {
      final config = await LspConfigLoader.loadAsync();
      _instance = LspServerRegistry._(config);
    }
  }

  /// Initializes the registry with a pre-loaded config.
  /// Used for parallel loading of configs.
  static void initializeWith(LspConfig config) {
    _instance ??= LspServerRegistry._(config);
  }

  /// Resets the registry (useful for testing or reloading config).
  static void reset() {
    _instance = null;
  }

  /// The map of server configurations.
  Map<String, LspServerConfig> get _servers => _config.servers;

  /// Get all registered server configurations.
  static Iterable<LspServerConfig> get all => instance._servers.values;

  /// Get server configuration by name.
  static LspServerConfig? getByName(String name) => instance._servers[name];

  /// Get server configuration for a file extension.
  static LspServerConfig? getForExtension(String ext) {
    final normalizedExt = ext.toLowerCase().replaceFirst('.', '');
    for (final server in instance._servers.values) {
      if (server.handlesExtension(normalizedExt)) {
        return server;
      }
    }
    return null;
  }

  /// Get server configuration for a language ID.
  static LspServerConfig? getForLanguageId(String langId) {
    for (final server in instance._servers.values) {
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
    for (final server in instance._servers.values) {
      if (server.extensions.contains(ext)) {
        return server.languageIds.first;
      }
    }

    // Fallback for languages without LSP config
    return LspServerDefaults.fallbackLanguageIds[ext] ?? 'plaintext';
  }

  /// Detect which server to use based on project files in a directory.
  static LspServerConfig? detectForProject(String rootPath) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return null;

    for (final server in instance._servers.values) {
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
    for (final server in instance._servers.values) {
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
