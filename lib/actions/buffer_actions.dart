import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../popup/buffer_selector.dart';

/// Buffer navigation and management commands.
class BufferActions {
  /// Switch to next buffer (:bn, :bnext)
  static void nextBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (e.bufferCount <= 1) {
      e.showMessage(.info('Only one buffer open'));
      return;
    }
    e.nextBuffer();
    e.showMessage(.info('Buffer ${e.currentBufferIndex + 1}/${e.bufferCount}'));
  }

  /// Switch to previous buffer (:bp, :bprev)
  static void prevBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (e.bufferCount <= 1) {
      e.showMessage(.info('Only one buffer open'));
      return;
    }
    e.prevBuffer();
    e.showMessage(.info('Buffer ${e.currentBufferIndex + 1}/${e.bufferCount}'));
  }

  /// Switch to buffer by number (:b <n>) or show buffer selector (:b)
  static void switchToBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (args.length < 2) {
      // No argument - show buffer selector
      BufferSelector.show(e);
      return;
    }
    final num = int.tryParse(args[1]);
    if (num == null || num < 1 || num > e.bufferCount) {
      e.showMessage(.error('Invalid buffer number: ${args[1]}'));
      return;
    }
    e.switchBuffer(num - 1);
    e.showMessage(.info('Buffer $num/${e.bufferCount}'));
  }

  /// Close current buffer (:bd, :bdelete)
  static void closeBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.closeBuffer(e.currentBufferIndex);
  }

  /// Force close current buffer (:bd!, :bdelete!)
  static void forceCloseBuffer(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.closeBuffer(e.currentBufferIndex, force: true);
  }

  /// List all buffers (:ls, :buffers) - shows interactive popup
  static void listBuffers(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    BufferSelector.show(e);
  }
}
