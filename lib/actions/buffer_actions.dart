import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../popup/buffer_selector.dart';
import '../types/line_edit_action_base.dart';

// ===== Buffer commands =====

/// Switch to next buffer (:bn, :bnext).
class CmdNextBuffer extends LineEditAction {
  const CmdNextBuffer();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (e.bufferCount <= 1) {
      e.showMessage(.info('Only one buffer open'));
      return;
    }
    e.nextBuffer();
    e.showMessage(.info('Buffer ${e.currentBufferIndex + 1}/${e.bufferCount}'));
  }
}

/// Switch to previous buffer (:bp, :bprev).
class CmdPrevBuffer extends LineEditAction {
  const CmdPrevBuffer();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (e.bufferCount <= 1) {
      e.showMessage(.info('Only one buffer open'));
      return;
    }
    e.prevBuffer();
    e.showMessage(.info('Buffer ${e.currentBufferIndex + 1}/${e.bufferCount}'));
  }
}

/// Switch to buffer by number (`:b <n>`) or show selector (`:b`).
class CmdSwitchToBuffer extends LineEditAction {
  const CmdSwitchToBuffer();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
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
}

/// Close current buffer (:bd, :bdelete).
class CmdCloseBuffer extends LineEditAction {
  const CmdCloseBuffer();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.closeBuffer(e.currentBufferIndex);
  }
}

/// Force close current buffer (:bd!, :bdelete!).
class CmdForceCloseBuffer extends LineEditAction {
  const CmdForceCloseBuffer();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.closeBuffer(e.currentBufferIndex, force: true);
  }
}

/// List all buffers (:ls, :buffers).
class CmdListBuffers extends LineEditAction {
  const CmdListBuffers();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    BufferSelector.show(e);
  }
}
