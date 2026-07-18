import 'dart:io';

/// A parsed file argument from the command line.
class CliFileArg {
  final String path;
  final String? lineArg;

  const CliFileArg(this.path, this.lineArg);
}

/// Parses command-line arguments for the editor.
///
/// Recognizes `path` arguments and vim-style `+<line>` modifiers that apply
/// to the preceding path. Directory arguments are not files; the first one
/// is reported separately via [directory].
class CliArgs {
  final List<CliFileArg> files;
  final String? directory;

  const CliArgs(this.files, this.directory);

  /// Parse [args] into file arguments and an optional directory.
  factory CliArgs.parse(List<String> args) {
    final files = <CliFileArg>[];
    String? directory;
    String? pendingPath;

    for (final arg in args) {
      if (arg.startsWith('+')) {
        if (pendingPath != null) {
          files.add(CliFileArg(pendingPath, arg));
          pendingPath = null;
        }
      } else {
        if (Directory(arg).existsSync()) {
          directory ??= arg;
          continue;
        }
        if (pendingPath != null) {
          files.add(CliFileArg(pendingPath, null));
        }
        pendingPath = arg;
      }
    }
    if (pendingPath != null) {
      files.add(CliFileArg(pendingPath, null));
    }
    return CliArgs(files, directory);
  }
}
