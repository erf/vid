import 'package:test/test.dart';
import 'package:vid/file_buffer/file_buffer.dart';

void main() {
  group('toAbsolutePath', () {
    test('normalizes ../ segments', () {
      final normal = FileBufferIo.toAbsolutePath('/a/b/c/test.txt');
      final withDotDot = FileBufferIo.toAbsolutePath('/a/b/../b/c/test.txt');

      expect(withDotDot, normal);
      expect(withDotDot.contains('..'), isFalse);
    });

    test('normalizes multiple ../ segments', () {
      final normal = FileBufferIo.toAbsolutePath('/a/b/test.txt');
      final withDotDot = FileBufferIo.toAbsolutePath('/a/b/c/d/../../test.txt');

      expect(withDotDot, normal);
    });

    test('normalizes ./ segments', () {
      final normal = FileBufferIo.toAbsolutePath('/a/b/test.txt');
      final withDot = FileBufferIo.toAbsolutePath('/a/./b/./test.txt');

      expect(withDot, normal);
    });

    test(
      'different relative paths to same file produce same absolute path',
      () {
        // Simulates: opening /projects/vid/lib/editor.dart from two directories
        final fromVid = FileBufferIo.toAbsolutePath(
          '/projects/vid/lib/editor.dart',
        );
        final fromProjects = FileBufferIo.toAbsolutePath(
          '/projects/vid/../vid/lib/editor.dart',
        );

        expect(fromProjects, fromVid);
      },
    );
  });
}
