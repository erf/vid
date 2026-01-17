import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';

/// Signature for motion functions.
/// [e] Editor instance
/// [f] FileBuffer instance
/// [offset] Current byte offset
/// Returns the new byte offset (cursor position)
typedef MotionFunction = int Function(Editor e, FileBuffer f, int offset);
