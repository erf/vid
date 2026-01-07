import 'dart:async';
import 'dart:io';

import 'package:vid/config.dart';
import 'package:vid/features/lsp/lsp_config_loader.dart';
import 'package:vid/features/lsp/lsp_server_config.dart';
import 'package:yaml/yaml.dart';

/// Loads configuration from YAML files at standard paths.
///
/// Search order (first found wins):
/// 1. `./config.yaml` (local project config)
/// 2. `$XDG_CONFIG_HOME/vid/config.yaml`
/// 3. `~/.config/vid/config.yaml`
class ConfigLoader {
  /// The name of the config file to search for.
  static const String configFileName = 'config.yaml';

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

  /// Returns the default user config file path.
  static String get defaultConfigPath => '$defaultConfigDir/$configFileName';

  /// Loads configuration from the first available config file.
  /// Returns default [Config] if no config file is found or on parse error.
  static Config load() {
    for (final path in configPaths) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          final contents = file.readAsStringSync();
          final yaml = loadYaml(contents);
          if (yaml is YamlMap) {
            return Config.fromMap(_yamlMapToMap(yaml));
          }
        } catch (e) {
          // Silently fall back to defaults on parse error
        }
      }
    }
    return const Config();
  }

  /// Loads configuration asynchronously from the first available config file.
  /// Returns default [Config] if no config file is found or on parse error.
  static Future<Config> loadAsync() async {
    for (final path in configPaths) {
      final file = File(path);
      if (await file.exists()) {
        try {
          final contents = await file.readAsString();
          final yaml = loadYaml(contents);
          if (yaml is YamlMap) {
            return Config.fromMap(_yamlMapToMap(yaml));
          }
        } catch (e) {
          // Silently fall back to defaults on parse error
        }
      }
    }
    return const Config();
  }

  /// Loads both editor config and LSP config in parallel.
  /// This is the preferred way to initialize the editor for faster startup.
  static Future<Config> loadAllAsync() async {
    final results = await Future.wait([
      loadAsync(),
      LspConfigLoader.loadAsync(),
    ]);

    // Initialize LSP registry with loaded config
    final lspConfig = results[1] as LspConfig;
    LspServerRegistry.initializeWith(lspConfig);

    return results[0] as Config;
  }

  /// Converts a [YamlMap] to a standard [Map<String, dynamic>].
  static Map<String, dynamic> _yamlMapToMap(YamlMap yaml) {
    final map = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is YamlMap) {
        map[key] = _yamlMapToMap(value);
      } else if (value is YamlList) {
        map[key] = value.toList();
      } else {
        map[key] = value;
      }
    }
    return map;
  }
}
