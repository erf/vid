import 'package:test/test.dart';
import 'package:vid/cli_args.dart';

void main() {
  test('parses single file', () {
    final args = CliArgs.parse(['foo.txt']);
    expect(args.files.length, 1);
    expect(args.files[0].path, 'foo.txt');
    expect(args.files[0].lineArg, isNull);
    expect(args.directory, isNull);
  });

  test('parses multiple files', () {
    final args = CliArgs.parse(['a.txt', 'b.txt']);
    expect(args.files.map((f) => f.path), ['a.txt', 'b.txt']);
  });

  test('line arg applies to preceding file', () {
    final args = CliArgs.parse(['foo.txt', '+42']);
    expect(args.files.length, 1);
    expect(args.files[0].path, 'foo.txt');
    expect(args.files[0].lineArg, '+42');
  });

  test('line arg without preceding file is ignored', () {
    final args = CliArgs.parse(['+42']);
    expect(args.files, isEmpty);
  });

  test('files around line arg are kept', () {
    final args = CliArgs.parse(['a.txt', '+10', 'b.txt']);
    expect(args.files.length, 2);
    expect(args.files[0].path, 'a.txt');
    expect(args.files[0].lineArg, '+10');
    expect(args.files[1].path, 'b.txt');
    expect(args.files[1].lineArg, isNull);
  });

  test('directory is reported separately, not as file', () {
    final args = CliArgs.parse(['.']);
    expect(args.files, isEmpty);
    expect(args.directory, '.');
  });

  test('directory mixed with files', () {
    final args = CliArgs.parse(['foo.txt', '.']);
    expect(args.files.map((f) => f.path), ['foo.txt']);
    expect(args.directory, '.');
  });

  test('first directory wins', () {
    final args = CliArgs.parse(['lib', 'test']);
    expect(args.directory, 'lib');
  });

  test('empty args', () {
    final args = CliArgs.parse([]);
    expect(args.files, isEmpty);
    expect(args.directory, isNull);
  });
}
