import 'dart:io';

bool fileExistsSync(String path) => File(path).existsSync();

List<int> readBytesSync(String path) => File(path).readAsBytesSync();

Future<String> readFileAsString(String path) => File(path).readAsString();

Future<void> writeFileAsString(String path, String content) async {
  await File(path).writeAsString(content);
}

bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;
