import 'dart:io';

/// XDG Base Directory specification utilities.
///
/// Provides standard paths for config, cache, and data directories
/// following the XDG Base Directory specification.
class XdgPaths {
  /// The application directory name.
  static const String appName = 'vid';

  // Environment variable names
  static const String _envHome = 'HOME';
  static const String _envXdgConfigHome = 'XDG_CONFIG_HOME';
  static const String _envXdgCacheHome = 'XDG_CACHE_HOME';
  static const String _envXdgDataHome = 'XDG_DATA_HOME';

  // Common environment variable getters
  static String? get _home => Platform.environment[_envHome];
  static String? get _xdgConfigHome => Platform.environment[_envXdgConfigHome];
  static String? get _xdgCacheHome => Platform.environment[_envXdgCacheHome];
  static String? get _xdgDataHome => Platform.environment[_envXdgDataHome];

  /// Returns the XDG config home directory.
  /// Falls back to `~/.config` if XDG_CONFIG_HOME is not set.
  static String get configHome {
    final xdgConfigHome = _xdgConfigHome;
    if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
      return xdgConfigHome;
    }
    final home = _home;
    if (home != null && home.isNotEmpty) {
      return '$home/.config';
    }
    return '.';
  }

  /// Returns the XDG cache home directory.
  /// Falls back to `~/.cache` if XDG_CACHE_HOME is not set.
  static String get cacheHome {
    final xdgCacheHome = _xdgCacheHome;
    if (xdgCacheHome != null && xdgCacheHome.isNotEmpty) {
      return xdgCacheHome;
    }
    final home = _home;
    if (home != null && home.isNotEmpty) {
      return '$home/.cache';
    }
    return '.';
  }

  /// Returns the XDG data home directory.
  /// Falls back to `~/.local/share` if XDG_DATA_HOME is not set.
  static String get dataHome {
    final xdgDataHome = _xdgDataHome;
    if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
      return xdgDataHome;
    }
    final home = _home;
    if (home != null && home.isNotEmpty) {
      return '$home/.local/share';
    }
    return '.';
  }

  /// Returns the application config directory (`$configHome/vid`).
  static String get appConfigDir => '$configHome/$appName';

  /// Returns the application cache directory (`$cacheHome/vid`).
  static String get appCacheDir => '$cacheHome/$appName';

  /// Returns the application data directory (`$dataHome/vid`).
  static String get appDataDir => '$dataHome/$appName';

  /// Ensures a directory exists, creating it if necessary.
  /// Returns the directory path.
  static String ensureDir(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return path;
  }

  /// Returns a list of config file paths to search, in priority order.
  ///
  /// 1. `./[localFileName]` (local project config, hidden dotfile)
  /// 2. `$XDG_CONFIG_HOME/vid/[globalFileName]`
  /// 3. `~/.config/vid/[globalFileName]`
  ///
  /// If [localFileName] is not provided, [globalFileName] is used for all paths.
  static List<String> configFilePaths(
    String globalFileName, [
    String? localFileName,
  ]) {
    localFileName ??= globalFileName;
    final paths = <String>[];

    // 1. Local project config (hidden dotfile)
    paths.add('${Directory.current.path}/$localFileName');

    // 2. XDG_CONFIG_HOME (explicit)
    final xdgConfigHome = _xdgConfigHome;
    if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
      paths.add('$xdgConfigHome/$appName/$globalFileName');
    }

    // 3. HOME/.config (fallback for XDG)
    final home = _home;
    if (home != null && home.isNotEmpty) {
      paths.add('$home/.config/$appName/$globalFileName');
    }

    return paths;
  }
}
