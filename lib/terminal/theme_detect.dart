import 'dart:io';

import '../esc.dart';
import '../highlighting/highlighter.dart';

/// Detects terminal background color using OSC 11 query.
/// Returns appropriate theme based on luminance.
class ThemeDetector {
  /// Query terminal background and return appropriate theme.
  /// Assumes terminal is already in raw mode.
  /// Falls back to [defaultTheme] if detection fails or times out.
  static Theme detectSync({
    Theme defaultTheme = Theme.dark,
    Duration timeout = const Duration(milliseconds: 50),
  }) {
    try {
      // Send OSC 11 query
      stdout.write(Esc.queryBackgroundColor);

      // Read response with timeout using sync read
      final buffer = <int>[];
      final deadline = DateTime.now().add(timeout);

      while (DateTime.now().isBefore(deadline)) {
        // Check if data is available (non-blocking would be ideal but we'll poll)
        try {
          final byte = stdin.readByteSync();
          if (byte == -1) break;
          buffer.add(byte);

          // Check if response is complete (ends with ST or BEL)
          final str = String.fromCharCodes(buffer);
          if (str.contains('\x1B\\') || str.contains('\x07')) {
            return _parseResponse(str, defaultTheme);
          }
        } catch (_) {
          break;
        }
      }

      return defaultTheme;
    } catch (_) {
      return defaultTheme;
    }
  }

  /// Parse OSC 11 response and determine theme.
  /// Response format: ESC ] 11 ; rgb:RRRR/GGGG/BBBB ST
  static Theme _parseResponse(String response, Theme defaultTheme) {
    // Match rgb:XXXX/XXXX/XXXX pattern (16-bit per channel)
    final rgbMatch = RegExp(
      r'rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)',
    ).firstMatch(response);

    if (rgbMatch == null) return defaultTheme;

    // Parse hex values (may be 2 or 4 hex digits per channel)
    final rHex = rgbMatch.group(1)!;
    final gHex = rgbMatch.group(2)!;
    final bHex = rgbMatch.group(3)!;

    // Normalize to 0-255 range
    final r = _normalizeColor(rHex);
    final g = _normalizeColor(gHex);
    final b = _normalizeColor(bHex);

    // Calculate relative luminance (sRGB)
    // https://www.w3.org/TR/WCAG20/#relativeluminancedef
    final luminance = 0.2126 * r / 255 + 0.7152 * g / 255 + 0.0722 * b / 255;

    // Light background if luminance > 0.5
    return luminance > 0.5 ? Theme.light : Theme.dark;
  }

  /// Normalize hex color value to 0-255 range.
  static int _normalizeColor(String hex) {
    final value = int.parse(hex, radix: 16);
    // If 4 hex digits (16-bit), scale down to 8-bit
    if (hex.length == 4) {
      return value >> 8;
    }
    // If 2 hex digits, use as-is
    return value;
  }
}
