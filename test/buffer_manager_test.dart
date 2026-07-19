import 'dart:io';

import 'package:test/test.dart';
import 'package:vid/buffer_manager.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/text_op.dart';

void main() {
  late List<FileBuffer> attached;
  late List<FileBuffer> activated;
  late List<FileBuffer> closed;
  late int emptyCalls;
  late BufferManager m;

  setUp(() {
    attached = [];
    activated = [];
    closed = [];
    emptyCalls = 0;
    m = BufferManager(
      workingDirectory: Directory.current.path,
      onAttach: attached.add,
      onActivated: activated.add,
      onBufferSwitch: (_, _) {},
      onOpened: (_) {},
      onClosing: closed.add,
      onEmpty: () => emptyCalls++,
    );
    m.add(FileBuffer(text: 'initial\n'));
  });

  test('seeds with one buffer, current is first', () {
    expect(m.count, 1);
    expect(m.current.text, 'initial\n');
    expect(m.currentIndex, 0);
  });

  test('add attaches and appends', () {
    final b = FileBuffer(text: 'second\n');
    m.add(b);
    expect(m.count, 2);
    expect(attached, contains(b));
  });

  test('switchToBuffer changes current and notifies', () {
    m.add(FileBuffer(text: 'second\n'));
    m.switchToBuffer(1);
    expect(m.currentIndex, 1);
    expect(m.current.text, 'second\n');
    expect(activated.single.text, 'second\n');
  });

  test('switchToBuffer ignores out-of-range index', () {
    m.switchToBuffer(5);
    expect(m.currentIndex, 0);
    expect(activated, isEmpty);
  });

  test('next and prev wrap around', () {
    m.add(FileBuffer(text: 'b\n'));
    m.add(FileBuffer(text: 'c\n'));
    m.next();
    expect(m.currentIndex, 1);
    m.next();
    expect(m.currentIndex, 2);
    m.next(); // wraps to 0
    expect(m.currentIndex, 0);
    m.prev(); // wraps to last
    expect(m.currentIndex, 2);
  });

  test('next/prev are no-ops with a single buffer', () {
    m.next();
    m.prev();
    expect(m.currentIndex, 0);
    expect(activated, isEmpty);
  });

  test('close refuses modified buffer without force', () {
    final b = m.current..text = 'changed\n';
    b.pushUndo(UndoGroup([]), 100); // make modified
    expect(m.current.modified, isTrue);
    expect(m.close(0), isFalse);
    expect(m.count, 1);
    expect(m.close(0, force: true), isTrue);
  });

  test('closing last buffer triggers onEmpty', () {
    expect(m.close(0, force: true), isTrue);
    expect(emptyCalls, 1);
    expect(m.count, 0);
  });

  test('close adjusts currentIndex when closing earlier buffer', () {
    m.add(FileBuffer(text: 'b\n'));
    m.add(FileBuffer(text: 'c\n'));
    m.switchToBuffer(2);
    expect(m.close(0, force: true), isTrue);
    expect(m.currentIndex, 1); // shifted down
    expect(m.current.text, 'c\n');
  });

  test('close clamps currentIndex when closing last buffer in list', () {
    m.add(FileBuffer(text: 'b\n'));
    m.switchToBuffer(1);
    expect(m.close(1, force: true), isTrue);
    expect(m.currentIndex, 0);
    expect(m.current.text, 'initial\n');
  });

  test('close notifies onClosing and onActivated', () {
    m.add(FileBuffer(text: 'b\n'));
    final closing = m.buffers[1];
    m.close(1, force: true);
    expect(closed, [closing]);
    expect(activated.single.text, 'initial\n');
  });

  test('hasUnsavedChanges and unsavedCount track modified', () {
    expect(m.hasUnsavedChanges, isFalse);
    expect(m.unsavedCount, 0);
    m.current.text = 'changed\n';
    m.current.pushUndo(UndoGroup([]), 100); // make modified
    expect(m.hasUnsavedChanges, isTrue);
    expect(m.unsavedCount, 1);
  });

  test('list marks current and modified buffers', () {
    m.add(FileBuffer(text: 'b\n', absolutePath: '/tmp/b.txt'));
    m.buffers[1].text = 'changed\n';
    m.buffers[1].pushUndo(UndoGroup([]), 100); // make modified
    final list = m.list;
    expect(list[0], startsWith('1% '));
    expect(list[1], startsWith('2 +'));
    expect(list[1], contains('b.txt'));
  });

  group('load', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('vid_buffer_manager_test');
      m = BufferManager(
        workingDirectory: tmp.path,
        onAttach: attached.add,
        onActivated: activated.add,
        onBufferSwitch: (_, _) {},
        onOpened: (_) {},
        onClosing: closed.add,
        onEmpty: () => emptyCalls++,
      );
      m.add(FileBuffer()); // untouched initial buffer
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    test('loads file, replacing untouched buffer', () {
      File('${tmp.path}/a.txt').writeAsStringSync('hello\n');
      final result = m.load('${tmp.path}/a.txt');
      expect(result.hasError, isFalse);
      expect(m.count, 1); // replaced, not added
      expect(m.current.text, 'hello\n');
    });

    test('loading same file twice returns existing buffer', () {
      File('${tmp.path}/a.txt').writeAsStringSync('hello\n');
      final first = m.load('${tmp.path}/a.txt').value!;
      m.add(FileBuffer(text: 'other\n'));
      final second = m.load('${tmp.path}/a.txt').value!;
      expect(identical(first, second), isTrue);
    });

    test('adds new buffer when current is modified', () {
      m.current.text = 'changed\n';
      m.current.pushUndo(UndoGroup([]), 100); // make modified
      File('${tmp.path}/a.txt').writeAsStringSync('hello\n');
      m.load('${tmp.path}/a.txt');
      expect(m.count, 2);
      expect(m.currentIndex, 1); // switched to new buffer
    });

    test('switchTo: false keeps current buffer', () {
      File('${tmp.path}/a.txt').writeAsStringSync('hello\n');
      m.current.text = 'changed\n';
      m.current.pushUndo(UndoGroup([]), 100); // make modified
      m.load('${tmp.path}/a.txt', switchTo: false);
      expect(m.currentIndex, 0);
      expect(m.count, 2);
    });

    test('returns error for missing file', () {
      final result = m.load('${tmp.path}/nope.txt');
      expect(result.hasError, isTrue);
    });
  });
}
