bool fileExistsSync(String path) => false;

List<int> readBytesSync(String path) =>
    throw UnsupportedError('File system not available on web');

Future<String> readFileAsString(String path) =>
    throw UnsupportedError('File system not available on web');

Future<void> writeFileAsString(String path, String content) =>
    throw UnsupportedError('File system not available on web');

bool get isMobilePlatform => false;
