import 'dart:io';

/// XDG Base Directory specification utilities.
///
/// Provides standard paths for config, cache, and data directories
/// following the XDG Base Directory specification.
class XdgPaths {
  /// The application directory name.
  static const String appName = 'vid';

  /// Returns the XDG config home directory.
  /// Falls back to `~/.config` if XDG_CONFIG_HOME is not set.
  static String get configHome {
    final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
      return xdgConfigHome;
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return '$home/.config';
    }
    return '.';
  }

  /// Returns the XDG cache home directory.
  /// Falls back to `~/.cache` if XDG_CACHE_HOME is not set.
  static String get cacheHome {
    final xdgCacheHome = Platform.environment['XDG_CACHE_HOME'];
    if (xdgCacheHome != null && xdgCacheHome.isNotEmpty) {
      return xdgCacheHome;
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return '$home/.cache';
    }
    return '.';
  }

  /// Returns the XDG data home directory.
  /// Falls back to `~/.local/share` if XDG_DATA_HOME is not set.
  static String get dataHome {
    final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
    if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
      return xdgDataHome;
    }
    final home = Platform.environment['HOME'];
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

  /// Returns a list of config file paths to search, in priority order.
  ///
  /// 1. `./[fileName]` (local project config)
  /// 2. `$XDG_CONFIG_HOME/vid/[fileName]`
  /// 3. `~/.config/vid/[fileName]`
  static List<String> configFilePaths(String fileName) {
    final paths = <String>[];

    // 1. Local project config
    paths.add('${Directory.current.path}/$fileName');

    // 2. XDG_CONFIG_HOME (explicit)
    final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
      paths.add('$xdgConfigHome/$appName/$fileName');
    }

    // 3. HOME/.config (fallback for XDG)
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      paths.add('$home/.config/$appName/$fileName');
    }

    return paths;
  }
}
