import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:appnew_0/src/utils/platform_file.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('platform_file_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('fileExistsSync returns true for existing file', () {
    final file = File('${tempDir.path}/exists.txt');
    file.writeAsStringSync('test');
    expect(fileExistsSync(file.path), isTrue);
  });

  test('fileExistsSync returns false for missing file', () {
    expect(fileExistsSync('${tempDir.path}/nope.txt'), isFalse);
  });

  test('readBytesSync reads file content as bytes', () {
    final file = File('${tempDir.path}/bytes.txt');
    file.writeAsStringSync('hello');
    final bytes = readBytesSync(file.path);
    expect(bytes, equals('hello'.codeUnits));
  });

  test('readFileAsString reads file content as string', () async {
    final file = File('${tempDir.path}/string.txt');
    file.writeAsStringSync('world');
    final content = await readFileAsString(file.path);
    expect(content, equals('world'));
  });

  test('writeFileAsString writes content to file', () async {
    final path = '${tempDir.path}/written.txt';
    await writeFileAsString(path, 'written');
    expect(File(path).readAsStringSync(), equals('written'));
  });

  test('isMobilePlatform returns a boolean on current platform', () {
    expect(isMobilePlatform, isA<bool>());
  });
}
