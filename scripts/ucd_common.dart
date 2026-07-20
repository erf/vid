import 'dart:convert';

import 'package:http/http.dart' as http;

/// Shared helpers for scripts that generate Dart tables from the official
/// Unicode Character Database (https://unicode.org/Public/...).
///
/// Used by gen_width_table.dart.

/// A remote UCD text file. Fetches once and extracts the standard header
/// metadata (`# File:`, `# Date:`, optional `# Version:`) alongside the lines.
class UcdSource {
  final String url;
  String filename = '';
  String date = '';
  String version = '';

  UcdSource(this.url);

  Future<List<String>> fetchLines() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download $url (${response.statusCode})');
    }
    final lines = LineSplitter.split(response.body).toList();
    filename = lines.first.replaceFirst('# ', '');
    date = lines[1].replaceFirst('# ', '');
    // Version is on a "# Version: 17.0" comment line (not the filename line).
    // Not all UCD files have one; leave empty if absent.
    final versionLine = lines.firstWhere(
      (l) => l.startsWith('# Version:'),
      orElse: () => '',
    );
    version = versionLine.replaceFirst('# Version:', '').trim();
    return lines;
  }

  /// Header comment for generated files, e.g. "EastAsianWidth-17.0.0.txt
  /// (Date: ...; Version: 17.0)".
  String get description =>
      '$filename ($date${version.isEmpty ? '' : '; Version: $version'})';
}

/// Parse a UCD range field like "1F600..1F64F" or "1F600" into (start, end).
(int, int) parseCodePointRange(String field) {
  final range = field.trim();
  if (range.contains('..')) {
    final bounds = range.split('..');
    return (int.parse(bounds[0], radix: 16), int.parse(bounds[1], radix: 16));
  }
  final value = int.parse(range, radix: 16);
  return (value, value);
}
