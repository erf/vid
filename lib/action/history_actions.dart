import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'action_base.dart';

/// Undo.
class Undo extends Action {
  const Undo();

  @override
  void call(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      f.undo(); // Restores selections internally
    }
    f.edit.reset();
  }
}

/// Redo.
class Redo extends Action {
  const Redo();

  @override
  void call(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      f.redo(); // Positions cursor internally
    }
    f.edit.reset();
  }
}

/// Repeat last edit.
class Repeat extends Action {
  const Repeat();

  @override
  void call(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatWithDot) {
      return;
    }
    e.commitEdit(f.prevEdit!);
  }
}

/// Repeat find direction.
enum RepeatFindDir { forward, reverse }

/// Repeat find string (; or ,).
class RepeatFind extends Action {
  final RepeatFindDir dir;
  const RepeatFind(this.dir);

  @override
  void call(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatFind) {
      return;
    }
    switch (dir) {
      case .forward:
        e.commitEdit(f.prevEdit!);
      case .reverse:
        final prev = f.prevEdit!;
        final reversedMotion = prev.motion.reversed;
        if (reversedMotion == null) return;

        // Set findStr for the motion to use
        f.edit.findStr = prev.findStr;

        // Execute the motion count times
        var newPos = f.cursor;
        for (int i = 0; i < prev.count; i++) {
          newPos = reversedMotion.fn(e, f, newPos);
        }
        f.cursor = newPos;
        f.edit.reset();
    }
  }
}
