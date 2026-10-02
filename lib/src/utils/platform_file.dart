import 'platform_file_io.dart'
    if (dart.library.js_interop) 'platform_file_web.dart'
    as pf;

/// Returns true if the file at [path] exists (IO only; always false on web).
bool fileExistsSync(String path) => pf.fileExistsSync(path);

/// Reads the file at [path] as raw bytes (IO only; throws on web).
List<int> readBytesSync(String path) => pf.readBytesSync(path);

/// Reads the file at [path] as a UTF-8 string (IO only; throws on web).
Future<String> readFileAsString(String path) => pf.readFileAsString(path);

/// Writes [content] as a UTF-8 string to the file at [path] (IO only; throws on web).
Future<void> writeFileAsString(String path, String content) =>
    pf.writeFileAsString(path, content);

/// True when the current platform is Android or iOS (always false on web).
bool get isMobilePlatform => pf.isMobilePlatform;
