import 'dart:io';

import 'package:yaml/yaml.dart';

import 'lsp_server_config.dart';
import 'lsp_server_defaults.dart';

/// Configuration loaded from the LSP servers YAML file.
class LspConfig {
  /// Whether LSP support is enabled globally.
  final bool enabled;

  /// Map of server key to server configuration.
  final Map<String, LspServerConfig> servers;

  const LspConfig({this.enabled = true, this.servers = const {}});

  /// Creates an [LspConfig] with default servers.
  factory LspConfig.withDefaults() {
    return LspConfig(enabled: true, servers: Map.from(defaultLspServers));
  }
}

/// Loads LSP server configuration from YAML files at standard paths.
///
/// Search order (first found wins):
/// 1. `./lsp_servers.yaml` (local project config)
/// 2. `$XDG_CONFIG_HOME/vid/lsp_servers.yaml`
/// 3. `$HOME/.config/vid/lsp_servers.yaml`
///
/// Falls back to hardcoded defaults if no config file is found.
class LspConfigLoader {
  /// The name of the LSP config file to search for.
  static const String configFileName = 'lsp_servers.yaml';

  /// The application config directory name.
  static const String appDirName = 'vid';

  /// Returns the list of config file paths to search, in priority order.
  static List<String> get configPaths {
    final paths = <String>[];

    // 1. Local project config
    paths.add('${Directory.current.path}/$configFileName');

    // 2. XDG_CONFIG_HOME
    final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
      paths.add('$xdgConfigHome/$appDirName/$configFileName');
    }

    // 3. HOME/.config (fallback for XDG)
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      paths.add('$home/.config/$appDirName/$configFileName');
    }

    return paths;
  }

  /// Returns the default user config directory path.
  static String get defaultConfigDir {
    final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
      return '$xdgConfigHome/$appDirName';
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return '$home/.config/$appDirName';
    }
    return '.';
  }

  /// Returns the default user LSP config file path.
  static String get defaultConfigPath => '$defaultConfigDir/$configFileName';

  /// Loads LSP configuration synchronously.
  /// Returns [LspConfig] with defaults if no config file is found.
  static LspConfig load() {
    for (final path in configPaths) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          final contents = file.readAsStringSync();
          return parseConfig(contents);
        } catch (_) {
          // Silently fall back to defaults on parse error
        }
      }
    }
    return LspConfig.withDefaults();
  }

  /// Loads LSP configuration asynchronously.
  /// Returns [LspConfig] with defaults if no config file is found.
  static Future<LspConfig> loadAsync() async {
    for (final path in configPaths) {
      final file = File(path);
      if (await file.exists()) {
        try {
          final contents = await file.readAsString();
          return parseConfig(contents);
        } catch (_) {
          // Silently fall back to defaults on parse error
        }
      }
    }
    return LspConfig.withDefaults();
  }

  /// Parses the YAML content into an [LspConfig].
  /// Exposed for testing - normally use [load] or [loadAsync].
  static LspConfig parseConfig(String contents) {
    try {
      final yaml = loadYaml(contents);
      if (yaml is! YamlMap) {
        return LspConfig.withDefaults();
      }
      return _parseYamlMap(yaml);
    } catch (_) {
      return LspConfig.withDefaults();
    }
  }

  /// Parses a validated YamlMap into an [LspConfig].
  static LspConfig _parseYamlMap(YamlMap yaml) {
    final enabled = yaml['enabled'] as bool? ?? true;
    final serversYaml = yaml['servers'];

    // Start with defaults, then merge/override with user config
    final servers = Map<String, LspServerConfig>.from(defaultLspServers);

    if (serversYaml is YamlMap) {
      for (final entry in serversYaml.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        if (value is YamlMap) {
          final config = _parseServerConfig(key, value);
          if (config != null) {
            servers[key] = config;
          }
        } else if (value == null || value == false) {
          // Allow disabling a default server by setting it to null or false
          servers.remove(key);
        }
      }
    }

    return LspConfig(enabled: enabled, servers: servers);
  }

  /// Parses a single server configuration from YAML.
  static LspServerConfig? _parseServerConfig(String key, YamlMap yaml) {
    final name = yaml['name'] as String?;
    final executable = yaml['executable'] as String?;

    // Name and executable are required
    if (name == null || executable == null) {
      return null;
    }

    return LspServerConfig(
      name: name,
      executable: executable,
      args: _parseStringList(yaml['args']),
      extensions: _parseStringSet(yaml['extensions']),
      languageIds: _parseStringSet(yaml['languageIds']),
      projectMarkers: _parseStringList(yaml['projectMarkers']),
      supportsSemanticTokens: yaml['supportsSemanticTokens'] as bool? ?? false,
      preferBuiltInHighlighting:
          yaml['preferBuiltInHighlighting'] as bool? ?? false,
    );
  }

  /// Parses a YAML list into a `List<String>`.
  static List<String> _parseStringList(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Parses a YAML list into a `Set<String>`.
  static Set<String> _parseStringSet(dynamic value) {
    return _parseStringList(value).toSet();
  }
}
